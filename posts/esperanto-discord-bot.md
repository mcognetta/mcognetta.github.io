@def title = "Discord Bot for Esperanto Transcription"
@def date = "06/19/2021"
@def tags = ["esperanto", "python", "discord"]
 
# X-System Transcription Discord Bot

In the days before Unicode, typists had to improvise when typing characters with diacritics (ĉ, ŭ, etc.). One popular system for marking diacritics was the “x-system”. One simply placed an “x” immediately after the character that they wanted to mark with a diacritic (cx -> ĉ, ux -> ŭ, etc.). There are some problems with this system though. There may be more than one viable diacritic for a character in a context; there may be ambiguity between diacritic-marking x’s and literal x’s, etc. However, the x-system took off for Esperanto, which does not have any of the aforementioned issues for pure Esperanto words.

These days, Esperanto language input methods are common, but people may not use them for a variety of reasons. It is still normal to see lots of text in chat rooms and on forums that use the x-system. I noticed that many users were still using the x-system even in the Esperanto community Discord channels, so I developed a small bot to automatically transcribe x-system text into the correct Unicode characters, so that a user could simply type as they wanted and the bot would handle the rest without prompting.

![bona](/assets/discord-bot-post/bona.gif)

As you can see, the x-system text is deleted and a new message with Unicode appears in its place. The username and profile picture match the original sender’s so as to not inhibit the flow of conversation.

The system I used to implement this is very simple. I simply assumed that all text in the channels with this bot would be in Esperanto, and so all *-x text should be reinterpreted as Unicode. This can lead to incorrect transcriptions. In this case, the user should be able to revert the change on command.

![pardonu](/assets/discord-bot-post/pardonu.gif)

Obviously, there are still some edge cases that exist -- for example, it is not possible for a user to revert only one word’s transcription in a message -- but for most cases, it gets the job done. The bot is also explicitly opt-in. In my server, it only corrects text typed by users with the “aŭttransskribiĝebla” role.


## Implementation

I used [Discord.py](https://github.com/Rapptz/discord.py), a fantastic Python API wrapper for Discord. One limitation of the Discord API is that bots cannot edit messages that were not created by them. This prohibits the most straightforward implementation where the bot just edits the content of a message to replace it with the Unicode transcription.

To get around this, I used [Webhooks](https://discordpy.readthedocs.io/en/stable/api.html#webhook), a method for sending messages to channels without using a bot or being a user. Webhooks allow for providing arbitrary message content and author information, so the original author’s information can be replicated. The transcribed message is then sent via the webhook and the original message is deleted, giving the appearance of it being edited.

The main message processing function looked something like this:

```python
@bot.event
async def on_message(message):
    author, content = message.author, message.content

    # filter out messages we don't want to process
    # for example, users who have not opted in or messages
    # that contain files, etc. that we do not want to be
    # responsible for
    if _message_metadata_filter(message):

        # a transcription function that returns a flag indicating
        # if any changes were made and the (possibly) edited text
        replaced, edited_text = replacer(content)

        if replaced:
            hook = await message.channel.create_webhook(name="bot")
            await message.delete()
            
            # send the transcribed message via the webhook
            # with the original author's information
            webhook_msg = await hook.send(
                edited_text,
                username=author.display_name + " | (transskribita)",
                avatar_url=author.avatar_url,
                # allows the webhook message info to be cached
                wait=True,
            )
            
            # stores the message in an LRU cache in case of
            # an undo command
            _queue_msg(author, content, channel, webhook_msg)
            await hook.delete()

    await bot.process_commands(message)
```

We also have an undo (`!malfaru`) function that deletes the edited message and replaces it with the original (again sent by a webhook). I imposed a cache size limit of 100 messages and implemented it as a plain deque. This is not ideal but can easily be changed in the event that this bot gets serious use.

The code can be found at [https://github.com/mcognetta/transskribilo-boto](https://github.com/mcognetta/transskribilo-boto).

## Esperanto

In case you were wondering about some of the Esperanto terms that were used, here is a quick summary.

The bot’s name is “transskribilo”, meaning “a tool for transcription”. Undo is called by “malfaru”, the command tense of “to undo”. The opt-in role is “aŭttransskribiĝebla” meaning “able to be automatically transcribed”. The text that appears after the username in transcribed messages is “(transkribita)”, the passive past participle “having been transcribed”. Finally, the reaction text that appears on `!malfaru` commands is “pardonu”, short for “pardonu min”, meaning “pardon me”.

Of these, aŭttransskribiĝebla is the most interesting grammatically. It is parsed as aŭt·trans·skrib·iĝ·ebl·a. “Aŭt-“ is the root for aŭto (as in automatically), “trans-“ and “skrib-“ combined give the root for “to transcribe”, “-iĝ-” is a suffix for turning an active verb into the passive voice, “-ebl-” is a suffix for “able to”, and “-a” is the adjective marker suffix.

Ĝis!