# PseudoVym

PseudoVym is a rudimentary PowerShell variant of the Unix text editor Vim, simply aiming
to bring some Vim functionality to PowerShell, since Windows does not have a native CLI 
text editor.  

Also, I wrote this on a whim because I saw a comment somewhere stating you needed to 
download third party applications for this functionality -- but I figured it would be
a relatively fun and easy project to do via PowerShell.

# Code / Functionality
Essentially, it's just a function with a perpetual WHILE loop prompting for a key input 
from the user, ignoring specific keys, and adding special functionality to others.

**Example:**

   *[] Left Alt   --  Save and Quit / Prompt User for Filename (if it doesn't exist)*

   *[] Right Alt  --  Quit without Saving*

   *[] Ctrl       --  Open rudimentary "Developer Console" styled after Vim syntax*
   
   *[] Delete     --  Remove entire Active Line*

The function name is "**PseudoVym**" however there's a built in alias called "**vim**".

Use **Get-Help** or the **-Help** switch for more info.

Use the **-Debug** switch for live verbose input and placement information.

# 200 IQ
Walmart brand *Vim*... Vim *Pseudonym*... *Pseudo-Vim*... **PSEUDOVYM**.  Cheeky, I'm aware.
