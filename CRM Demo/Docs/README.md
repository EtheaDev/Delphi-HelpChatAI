# Documents to attach

Two files to try the paper clip of the assistant with. They are not read by
the application: they exist to be attached to a question, so that the model
reads them and you see what comes of it.

| File | What it is |
| --- | --- |
| `lead-request.pdf` | A request for information from a company that is not in the CRM yet. One page, the fields of a lead scattered in it as they would be in a real one. |
| `call-notes.txt` | What somebody wrote down during the follow-up call: the details the PDF does not carry. |

Both demos accept attachments (`Settings.Attachments.Enabled` is True on the
`HelpChat` component of their main form; the library default is False).

## What to try

Open the chat, drop the files on the panel - or press the paper clip, whose dialog takes
both at once - and ask:

- *"Which company and which contact does the attached document name, and what
  is the budget?"* - the model answers from the PDF.
- *"Create a lead from the attached request, using the data in it."* - the
  model reads the document and calls the `create_lead` action of the demo,
  which asks you to confirm and then opens the lead it made.
- Attach both files and ask *"when should I call them back, and why EUR?"* -
  the answer comes from the notes, which the PDF knows nothing about.

The attachments stay with the conversation until you clear it with ↺, so a
second question about the same document needs no second upload.
