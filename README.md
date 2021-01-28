# PseudoVym

PseudoVym is a rudimentary PowerShell variant of the Unix text editor Vim, simply aiming
to bring some Vim functionality to PowerShell, since Windows does not have a native CLI 
text editor.  

Also, I wrote this on a whim because I saw a comment somewhere stating you needed to 
download third party applications for this functionality -- but I figured it would be
a relatively fun and easy project to do via PowerShell.

# Code / Functionality
The function name is "**PseudoVym**" however there's a built in alias called "**vim**".

Use **Get-Help** or the **-Help** switch for more info.

Use the **-Debug** switch for live verbose input and placement information.

Essentially, this is a large function with a perpetual WHILE loop prompting for key input 
from the user using **$Host.UI.RawUI.ReadKey** -- then ignoring specific keys and adding special
functionality to others based on their **VirtualKeyCodes**.

**Key Functionality:**

   *[] **Left Alt**   --  **[NOT SSH COMPATIBLE]** Save and Quit (prompt for filename if one isn't set)*

   *[] **Right Alt**  --  **[NOT SSH COMPATIBLE]** Quit without Saving*
   
   *[] **F1**         --  Save and Quit (prompt for filename if one isn't set)*

   *[] **F2**         --  Quit without Saving*

   *[] **F3**       --  Open Vim styled "Developer Console"*
   
   *[] **Delete**     --  Remove entire Active Line*
   
   *[] **PageUp**     --  Jump to First Line*
   
   *[] **PageDown**   --  Jump to Last Line*
   
   *[] **Enter**      --  Create new line after Active Line (and move remaining text)*
   
   *[] **ArrowKeys**  --  Change Active Line and Character Placement*

When inputting a filename, all extensions are supported.  When no file extension is input,
PseudoVym will search the PWD for a file with a matching base name to open; if no match
is found, then the file extension will default to **.txt** and input will be NULL.

# Developer Console
When in the Developer Console, type "help" to display a list available commands.

**Available Commands:**

   *[] **w**         --  Save File (prompt for filename if one isn't set)*
   
   *[] **q**          --  Quit PseudoVym without Saving*
   
   *[] **wq**         --  Save and Quit PseudoVym*
   
   *[] **set file=**  --  Set / Change Output Filename (Requires file extension; **Syntax:** 'set file=TestName.txt')*
   
   *[] **set path=**  --  Set / Change Output Path (Requires absolute path; NO file; **Syntax:** 'set path=C:\Users\Bobby\Documents')*
   
   *[] **dbg**        --  Toggle Debugger*
   
   *[] **cls**        --  Clear Console Output*
   
   *[] **:**          --  Exit Developer Console*
   
# Notes
Recommended usage is copy and pasting script contents into your **$PROFILE**.

Does **NOT** work in PowerShell ISE; tested in PowerShell **v7.0.3** and **v5.1.19041.1**.

# 200 IQ
Walmart brand *Vim*... Vim *Pseudonym*... *Pseudo-Vim*... **PSEUDOVYM**.  Cheeky, I'm aware.
