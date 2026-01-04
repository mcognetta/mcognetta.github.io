@def title = "Decoding GPT-Style Tokens"
@def date = "01/04/2026"
@def tags = ["tokenization", "ml"]

@def rss_description = "Decoding the GPT-style token representation."
@def rss_pubdate = Date(2026, 01, 04)

# Decoding GPT-Style Tokens

If you go and look at some tokenizers on HuggingFace, sometimes you will encounter tokens in a vocabulary or merge list that look like gibberish. For example, in the [Llama3 tokenizer](https://huggingface.co/meta-llama/Meta-Llama-3-8B/blob/main/tokenizer.json), you can find tokens like:

```
".conditions": 99804,
"ĠHess": 99805,
"MEMORY": 99806,
"ĠAvalanche": 99807,
"()}}Ċ": 99808,
"Ġtriplet": 99809,
"Ġlabyrinth": 99810,
```

which are generally meaningful to a human (other than the odd Ġ character), but also tokens like:

```
"Ð¾Ð¶Ðµ": 103308,
"å¤ľ": 103309,
"ĠÐ½ÑĥÐ¶Ð½Ð¾": 103310,
"å½©": 103311,
"çĪ±": 103312,
"ĠhoÃłn": 103313,
"Ã¼nÃ¼": 103314,
```

which are pretty much meaningless to a human.[^1]

You may already be aware that the Ġ character [signifies a space at the beginning of a word](https://en.wikipedia.org/wiki/%C4%A0#Computer_encoding), but how about the rest? They come from the fact that GPT-style tokenizers are *byte-level* tokenizers -- the base character is a byte and we treat the input as the byte sequence of its Unicode UTF8 encoding.

So, assuming the token we want to look at represents a valid byte sequence, we'd like to be able to quickly get its original Unicode representation for tasks like auditing the tokenizer vocabulary, assessing the diversity of languages, or building the required subword automata for [constrained generation](https://arxiv.org/abs/2407.08103).

## Token Encoding/Decoding

GPT-style tokenizers use bytes as the base representation, but when serializing the tokenizer or pretokenized text (i.e., text that has already been converted into a byte sequence), they convert the byte sequences to a different format so that we never have to deal with unprintable bytes. For example, if we were to just output the raw bytes represented in ASCII, then some of the bytes would fall into the unprintable control characters range, which would be annoying to deal with in a serialized format. Instead, we map all of the control bytes to some other (non-ASCII, but printable) Unicode character and then when we serialize, all of the output byte representations are printable.

GPT [implements](https://github.com/openai/gpt-2/blob/9b63575ef42771a015060c964af2c3da4cf7c8ab/src/encoder.py#L9) the byte-to-character mapping like so:

```python
def bytes_to_unicode():
    """
    Returns list of utf-8 byte and a corresponding list of unicode strings.
    The reversible bpe codes work on unicode strings.
    This means you need a large # of unicode characters in your vocab if you want to avoid UNKs.
    When you're at something like a 10B token dataset you end up needing around 5K for decent coverage.
    This is a signficant percentage of your normal, say, 32K bpe vocab.
    To avoid that, we want lookup tables between utf-8 bytes and unicode strings.
    And avoids mapping to whitespace/control characters the bpe code barfs on.
    """
    bs = list(range(ord("!"), ord("~")+1))+list(range(ord("¡"), ord("¬")+1))+list(range(ord("®"), ord("ÿ")+1))
    cs = bs[:]
    n = 0
    for b in range(2**8):
        if b not in bs:
            bs.append(b)
            cs.append(2**8+n)
            n += 1
    cs = [chr(n) for n in cs]
    return dict(zip(bs, cs))
```

This first collects a subset of printable characters in [extended ASCII](https://www.ascii-code.com/), converted to their decimal representation, into the list `bs`. For example, all of the characters between "!" (ASCII decimal 33) and "~" (ASCII decimal 126) are printable and are included in `bs`, but DEL (ASCII decimal 127) is not printable and not included.[^2] At this point, the list `cs` is initialized as a copy of `bs`. Then, we loop back through all 256 possible byte values and, for each byte that is not already in `bs`, we append it to `bs` and append the next available Unicode code point (starting from 256) to `cs`. Finally, `cs` is converted from code points to their corresponding Unicode characters. Now we have a mapping from bytes to printable characters:

```python
{33: '!', 34: '"', 35: '#', 36: '$', 37: '%', 38: '&', 39: "'", 40: '(', 41: ')', 42: '*', 43: '+', 44: ',', 45: '-', 46: '.', 47: '/', 48: '0', 49: '1', 50: '2', 51: '3', 52: '4', 53: '5', 54: '6', 55: '7', 56: '8', 57: '9', 58: ':', 59: ';', 60: '<', 61: '=', 62: '>', 63: '?', 64: '@', 65: 'A', 66: 'B', 67: 'C', 68: 'D', 69: 'E', 70: 'F', 71: 'G', 72: 'H', 73: 'I', 74: 'J', 75: 'K', 76: 'L', 77: 'M', 78: 'N', 79: 'O', 80: 'P', 81: 'Q', 82: 'R', 83: 'S', 84: 'T', 85: 'U', 86: 'V', 87: 'W', 88: 'X', 89: 'Y', 90: 'Z', 91: '[', 92: '\\', 93: ']', 94: '^', 95: '_', 96: '`', 97: 'a', 98: 'b', 99: 'c', 100: 'd', 101: 'e', 102: 'f', 103: 'g', 104: 'h', 105: 'i', 106: 'j', 107: 'k', 108: 'l', 109: 'm', 110: 'n', 111: 'o', 112: 'p', 113: 'q', 114: 'r', 115: 's', 116: 't', 117: 'u', 118: 'v', 119: 'w', 120: 'x', 121: 'y', 122: 'z', 123: '{', 124: '|', 125: '}', 126: '~', 161: '¡', 162: '¢', 163: '£', 164: '¤', 165: '¥', 166: '¦', 167: '§', 168: '¨', 169: '©', 170: 'ª', 171: '«', 172: '¬', 174: '®', 175: '¯', 176: '°', 177: '±', 178: '²', 179: '³', 180: '´', 181: 'µ', 182: '¶', 183: '·', 184: '¸', 185: '¹', 186: 'º', 187: '»', 188: '¼', 189: '½', 190: '¾', 191: '¿', 192: 'À', 193: 'Á', 194: 'Â', 195: 'Ã', 196: 'Ä', 197: 'Å', 198: 'Æ', 199: 'Ç', 200: 'È', 201: 'É', 202: 'Ê', 203: 'Ë', 204: 'Ì', 205: 'Í', 206: 'Î', 207: 'Ï', 208: 'Ð', 209: 'Ñ', 210: 'Ò', 211: 'Ó', 212: 'Ô', 213: 'Õ', 214: 'Ö', 215: '×', 216: 'Ø', 217: 'Ù', 218: 'Ú', 219: 'Û', 220: 'Ü', 221: 'Ý', 222: 'Þ', 223: 'ß', 224: 'à', 225: 'á', 226: 'â', 227: 'ã', 228: 'ä', 229: 'å', 230: 'æ', 231: 'ç', 232: 'è', 233: 'é', 234: 'ê', 235: 'ë', 236: 'ì', 237: 'í', 238: 'î', 239: 'ï', 240: 'ð', 241: 'ñ', 242: 'ò', 243: 'ó', 244: 'ô', 245: 'õ', 246: 'ö', 247: '÷', 248: 'ø', 249: 'ù', 250: 'ú', 251: 'û', 252: 'ü', 253: 'ý', 254: 'þ', 255: 'ÿ', 0: 'Ā', 1: 'ā', 2: 'Ă', 3: 'ă', 4: 'Ą', 5: 'ą', 6: 'Ć', 7: 'ć', 8: 'Ĉ', 9: 'ĉ', 10: 'Ċ', 11: 'ċ', 12: 'Č', 13: 'č', 14: 'Ď', 15: 'ď', 16: 'Đ', 17: 'đ', 18: 'Ē', 19: 'ē', 20: 'Ĕ', 21: 'ĕ', 22: 'Ė', 23: 'ė', 24: 'Ę', 25: 'ę', 26: 'Ě', 27: 'ě', 28: 'Ĝ', 29: 'ĝ', 30: 'Ğ', 31: 'ğ', 32: 'Ġ', 127: 'ġ', 128: 'Ģ', 129: 'ģ', 130: 'Ĥ', 131: 'ĥ', 132: 'Ħ', 133: 'ħ', 134: 'Ĩ', 135: 'ĩ', 136: 'Ī', 137: 'ī', 138: 'Ĭ', 139: 'ĭ', 140: 'Į', 141: 'į', 142: 'İ', 143: 'ı', 144: 'Ĳ', 145: 'ĳ', 146: 'Ĵ', 147: 'ĵ', 148: 'Ķ', 149: 'ķ', 150: 'ĸ', 151: 'Ĺ', 152: 'ĺ', 153: 'Ļ', 154: 'ļ', 155: 'Ľ', 156: 'ľ', 157: 'Ŀ', 158: 'ŀ', 159: 'Ł', 160: 'ł', 173: 'Ń'}
```

Note that in the table above, the token "Ġ" corresponds to the byte value 32, which is the space character in ASCII (decimal 32) and explains its use as the leading space character in a token. Additionally, some ASCII values like the English alphabet, numbers, and some punctuation are assigned to themselves in the encoding table. This helps preserve the human readability of serialized/encoded English tokens where possible.

The byte mapping and its inverse are saved for future use:

```python
byte_encoder = bytes_to_unicode()
byte_decoder = {v: k for k, v in byte_encoder.items()}
```

When given a token to serialize, we convert it to a byte sequence and map it to the corresponding character sequence via the byte encoding.

```python
def encode_token(token: str) -> str:
    return ''.join(byte_encoder[b] for b in token.encode('utf8'))

encode_token(' нужно') # -> "ĠÐ½ÑĥÐ¶Ð½Ð¾"
```

To recover the token from the serialized form, we do the opposite -- get the byte associated with each token, construct a byte sequence, and reinterpret it as UTF8.[^3]

```python
def decode_token(encoded_token: str) -> str:
    return bytes(byte_decoder[c] for c in encoded_token).decode('utf8')
    
decode_token("ĠÐ½ÑĥÐ¶Ð½Ð¾") # -> ' нужно'
```



## HuggingFace Tokenizers' Implementation

This token encoding is present in the HuggingFace Tokenizers library, via the `ByteLevel` decoder. The `byte_to_unicode()` function is reimplemented [here](https://github.com/huggingface/tokenizers/blob/ecad3f18a3e340635f5393cfb22cf70d3502f64a/tokenizers/src/pre_tokenizers/byte_level.rs#L15) and is utilized in the `ByteLevel` normalizer [here](https://github.com/huggingface/tokenizers/blob/ecad3f18a3e340635f5393cfb22cf70d3502f64a/tokenizers/src/normalizers/byte_level.rs#L41). One potential edge case is that the current `ByteLevel` implementation assumes that the exact GPT byte-to-character mapping is used by the tokenizer. However, one could easily define another byte-to-character mapping which would then not be supported by HuggingFace (though I have no examples of this in practice, and there may be some workaround within Tokenizers that I am unaware of). 



-----------------------------------

[^1]: Not all tokenizers will suffer from this issue. For example, tokenizers that are built on SentencePiece, which uses Unicode characters, not bytes, for the base representation will always have human-readable tokens. These tokenizers use byte-level fallbacks to encode OOV tokens, but such tokens do not appear in the vocabulary list. An example is the [Llama2 tokenizer](https://huggingface.co/meta-llama/Llama-2-7b-hf/blob/main/tokenizer.json).

[^2]: However, "‰" (ASCII decimal 137) *is* printable, but not included in `bs`, hence why we say a `bs` is seeded with a  *subset* of printable characters.

[^3]: Note that not all tokens can be decoded, since the byte sequence may not correspond to a valid UTF8 sequence. These cases should be handled specially, and we omit it in this post for simplicity.
