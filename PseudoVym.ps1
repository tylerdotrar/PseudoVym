function PseudoVym {
#.SYNOPSIS
# Rudimentary PowerShell variant of Vim.
# ARBITRARY VERSION NUMBER:  2.1.7
# AUTHOR:  Tyler McCann (@tyler.rar)
#
#.DESCRIPTION
# Simple script that aims to bring some Vim functionality
# to PowerShell, since Windows / PowerShell does not have 
# a native CLI text editor.
#
# Parameters:
#    -File      -->  (Optional) Input/output file
#    -Help      -->  (Optional) Return Get-Help info
#    -Debug     -->  (Optional) Display position and input info
#
# Special Keys:
#    Left Alt   -->  Save and Quit
#    Right Alt  -->  Quit
#    Ctrl       -->  Open Developer Console
#    Delete     -->  Remove entire Active Line
#
# Developer Console:
#    help       -->  List available commands
#
# Debug:
#    Preface    -->  Content BEFORE user input
#    Remainder  -->  Content AFTER user input
#    CharIndex  -->  Reverse Character Index
#    LineIndex  -->  Active Line
#
# 'Save as:' Prompts:
#    back       -->  Exit from prompt

    [Alias('vim')]
    Param ( [string]$File, [switch]$Help, [switch]$Debug )

    # Live Visual Formatting of Text
    function Vim-Formatting ([switch]$DevConsole) {
        ### Header formatting

        # Version Number
        Write-Host "PseudoVym " -ForegroundColor Yellow -NoNewline ; Write-Host "(v2.1.7)"

        # Output path
        if ($Debug -or $newPath) {
            Write-Host "Output Path: " -ForegroundColor Yellow -NoNewline
            if ($newPath) { Write-Host "$newPath" }
            else { Write-Host "$PWD" }
        }

        # Active Filename
        Write-Host "Filename: " -ForegroundColor Yellow -NoNewline
        if ($File) {
            if ($Changes) { Write-Host "$File" -NoNewLine ; Write-Host "*" -ForegroundColor DarkRed }
            else { Write-Host "$File" }
        }
        else {
            if ($Changes) { Write-Host "N/A" -NoNewLine ; Write-Host "*" -ForegroundColor DarkRed }
            else { Write-Host "N/A" }
        }
        Write-Host ""

        # Format spacing in front of text (1)
        $MaxLength = ($InputArray.Count - 1 | Measure-Object -Character).characters + 2

        # Calculate debug delimiter line length using longest line of text
        if ($Debug) {
            foreach ($Line in $InputArray) { 
                $TempDelim = $Line.Length + $MaxLength
                if ($TempDelim -gt $DelimLen) { $DelimLen = $TempDelim }
            }
            $Delim = "-" * $DelimLen
        }

        # Iterate for every line
        for ($Index=0; $Index -lt $InputArray.Count; $Index++) {
            # Format spacing in front of text (2)
            $Length = $MaxLength - ($Index | Measure-Object -Character).characters
            $Space = " " * $Length

            # Contents of the iterated line
            $Line = $InputArray[$Index]

            # Debug banner
            if ($Debug -and $Index -eq 0) { Write-Host "Debug Mode:`n$Delim`n" }

            # If iterated line is the active line
            if ($Index -eq $ArrayDir) {
                $VisualInput = $NULL
                $Remainder = $NULL
                Write-Host "$Index$Space" -ForegroundColor DarkRed -NoNewline
                
                # Formatting for non-empty lines
                if ($Line.Length -ge 1) {
                    # Input mark
                    $ActiveChar = $Line[$CharDir + 1]

                    # Input text BEFORE input mark
                    for ($Char = (-$Line.Length); $Char -le $CharDir; $Char++) { $VisualInput += $Line[$Char] }

                    # Input mark is NOT at the end of the line
                    if ($CharDir -ne -1) { 
                        # Remainder AFTER input mark
                        for ($Char = ($CharDir + 1); $Char -le -1; $Char++) {
                            if ($Char -ne -1) { $Remainder += $Line[$Char + 1] }
                        }
                        $DebugRemainder = $ActiveChar + $Remainder

                        Write-Host $VisualInput -NoNewline ; Write-Host $ActiveChar -ForegroundColor Black -BackgroundColor White -NoNewline ; Write-Host $Remainder
                    }

                    # Input mark IS at the end of the line
                    else { 
                        $VisualInput = $Line
                        Write-Host $VisualInput -NoNewline ; Write-Host " " -ForegroundColor Black -BackgroundColor White
                    }
                }

                # Formatting for empty lines 
                else { Write-Host " " -ForegroundColor Black -BackgroundColor White }
            }

            # If iterated line is NOT the active line
            else { Write-Host "$Index$Space" -ForegroundColor Yellow -NoNewline ; Write-Host $Line }
        }

        # Useful debug info
        if ($Debug) { 
            Write-Host "`n$Delim"
            Write-Host "Preface    " -NoNewline ; Write-Host "-->  " -ForegroundColor DarkRed -NoNewline ; Write-Host "'$VisualInput'"
            Write-Host "Remainder  " -NoNewline ; Write-Host "-->  " -ForegroundColor DarkRed -NoNewline ; Write-Host "'$DebugRemainder'"
            Write-Host "CharIndex  " -NoNewline ; Write-Host "-->  " -ForegroundColor DarkRed -NoNewline ; Write-Host "$CharDir"
            Write-Host "LineIndex  " -NoNewline ; Write-Host "-->  " -ForegroundColor DarkRed -NoNewline ; Write-Host "$ArrayDir"
        }
        Write-Host ""

        # Returned to create a buffer, allowing for left/right arrow key functionality
        if (!$DevConsole) { return $VisualInput, $DebugRemainder }
    }

    # Developer Console
    function Vim-DevConsole {
        while ($TRUE) {
            Write-Host ":" -ForegroundColor Yellow -NoNewline

            # User input
            $DevOption = Read-Host

            # List available commands
            if ($DevOption -eq "help") { 
                Write-Host "  w" -ForegroundColor Yellow -NoNewline ; Write-Host "               -->  Save"
                Write-Host "  q" -ForegroundColor Yellow -NoNewline ; Write-Host "               -->  Quit"
                Write-Host "  wq" -ForegroundColor Yellow -NoNewLine ; Write-Host "              -->  Save and Quit"
                Write-Host "  set file=*" -ForegroundColor Yellow -NoNewLine ; Write-Host "      -->  Output Filename"
                Write-Host "  set path=*" -ForegroundColor Yellow -NoNewline ; Write-Host "      -->  Output Directory"
                #Write-Host "  set encoding=*" -ForegroundColor Yellow -NoNewline ; Write-Host "  -->  Output Encoding"
                Write-Host "  cls" -ForegroundColor Yellow -NoNewline ; Write-Host "             -->  Clear Screen"
                Write-Host "  :" -ForegroundColor Yellow -NoNewline ; Write-Host "               -->  Exit Developer Console"
            }

            # Save
            elseif ($DevOption -eq "w") { 
                while ($TRUE) {
                    # Prompt for filename if not already set
                    if (!$File) { $TempFile = Read-Host "Save as" }

                    # Return to developer console without saving
                    if ($TempFile -and ($TempFile -eq "back")) { break }
                    # Error correction
                    elseif ($TempFile -and ($TempFile -notlike "*.*")) { Write-Host "Invalid input." -ForegroundColor DarkRed }
                    # Save file
                    else {
                        if (!$File) { $File = $TempFile }
                            
                        # Set output file path to current directory or user input directory (set path=*)
                        if (!$newPath) { $FileOut = "$PWD\$File" }
                        else {
                            if (!(Test-Path -LiteralPath $newPath)) { New-Item -Path $newPath -ItemType Directory | Out-Null }
                            $FileOut = "$newPath\$File"
                        }

                        # Save file, Remove Text Change Visual Indicator, Return to Console
                        [System.IO.File]::WriteAllLines($FileOut, $InputArray)
                        Write-Host "File saved." -ForegroundColor DarkGreen
                        $Changes = $FALSE

                        break
                    }
                }
            }

            # Quit PseudoVym
            elseif ($DevOption -eq "q") { 
                Clear-Host
                return $File, $newPath, $TRUE
            }

            # Save and Quit
            elseif ($DevOption -eq "wq") {
                while ($TRUE) { 
                    if (!$File) { $TempFile = Read-Host "Save as" }

                    # Return to developer console without saving
                    if ($TempFile -and ($TempFile -eq "back")) { break }
                    # Error correction
                    elseif ($TempFile -and ($TempFile -notlike "*.*")) { Write-Host "Invalid input." -ForegroundColor DarkRed }
                    # Save file
                    else {
                        if (!$File) { $File = $TempFile }

                        # Set output file path to current directory or user input directory (set path=*)
                        if (!$newPath) { $FileOut = "$PWD\$File" }
                        else {
                            if (!(Test-Path -LiteralPath $newPath)) { New-Item -Path $newPath -ItemType Directory | Out-Null }
                            $FileOut = "$newPath\$File"
                        }

                        # Save file and Exit PseudoVym
                        [System.IO.File]::WriteAllLines($FileOut, $InputArray)
                        Clear-Host

                        return $File, $newPath, $TRUE
                    }
                }
            }

            # Return to text contents
            elseif ($DevOption -eq ":") { return $File, $newPath, $FALSE }

            # Set output file directory (prefably absolute path)
            elseif (($DevOption -like "set path=*") -and ($DevOption -notlike "*.*") -and ($DevOption -like "set path=*:\*") -and ($DevOption -notlike "*\")) {
                $newPath = $DevOption.Replace("set path=",$NULL)
                Write-Host "Output path saved." -ForegroundColor DarkGreen
            }

            # Set filename (useful for copying files)
            elseif (($DevOption -like "set file=*") -and ($DevOption -like "*.*")) {
                $File = $DevOption.Replace("set file=",$NULL)
                Write-Host "Filename saved." -ForegroundColor DarkGreen
            }


            # Clear console screen
            elseif ($DevOption -eq "cls") {
                Clear-Host
                Vim-Formatting -DevConsole
            }

            # Error correction
            else { Write-Host "Invalid input." -ForegroundColor DarkRed }
        }
    }

    # KeyCodes:
    <#
    Tab         = VirtualKeyCode 9
    CapsLock    = VirtualKeyCode 20
    Shift       = VirtualKeyCode 16
    Enter       = VirtualKeyCode 13
    Ctrl        = VirtualKeyCode 17
    Alt         = VirtualKeyCode 18
    Backspace   = VirtualKeyCode 8
    ArrowUp     = VirtualKeyCode 38
    ArrowDown   = VirtualKeyCode 40
    ArrowLeft   = VirtualKeyCode 37
    ArrowRight  = VirtualKeyCode 39
    Escape      = VirtualKeyCode 27
    Delete      = VirtualKeyCode 46
    Insert      = VirtualKeyCode 45
    PageUp      = VirtualKeyCode 33
    PageDown    = VirtualKeyCode 34
    Home        = VirtualKeyCode 36
    End         = VirtualKeyCode 35
    FuncKeys    = VirtualKeyCode 112 - 123
    #>

    # VirtualKeyCodes to be Ignored
    $FuncKeys = 112..123
    $Others = 16,27,45,33,34,35,36
    $Stinky = $Others + $FuncKeys

    # Return help info
    if ($Help) { Get-Help PseudoVym ; return }

    # Format input filename
    if ($File -and ($File -like ".\*")) { $File = $File.Replace(".\",$NULL) }
    if ($File -and ($File -notlike "*.*")) { 
        $TempFile = (Get-ChildItem "$File*").Name

        # Append .txt if file extension not explicitly stated and base filename not found.
        if (!$TempFile) { $File = $TempFile + ".txt" }
        else { $File = $TempFile }
    }

    # Load existing file
    if ($File -and (Test-Path -LiteralPath $PWD\$File)) {
        $Skip = $TRUE
        $InputArray = @()
        $LineCount = 0

        foreach ($Line in (Get-Content -LiteralPath $PWD\$File)) {
            $InputArray += $Line
            $LineCount++
        }

        $ArrayDir = ($LineCount - 1)
        $Input = $InputArray[$ArrayDir]
        $CharDir = -1
    }
    # Start new file
    else {
        if ($File) { $Changes = $TRUE }
        $Input = $NULL
        $ArrayDir = 0
        $CharDir = -1
    }

    # Main Functionality
    while ($TRUE) {

        # Refresh screen every time there is input
        Clear-Host

        # Exit PseudoVym via Developer Console
        if ($ConsoleExit) { return }

        # Initialize input / Update selected line with new input
        if (!$Skip) {
            if (!$InputArray) { $InputArray = @("$Input") }
            else { $InputArray[$ArrayDir] = $Input }
        }
        $Skip = $FALSE

        # Call Live Visual Formatting / create input and remainder buffers
        $TempInput, $TempRemainder = Vim-Formatting

        # Create File output path
        if (!$NewPath -and $File) { $FileOut = "$PWD\$File" }
        elseif ($NewPath -and $File) { $FileOut = "$newPath\$File" }

        # Establish remainder for left/right arrow key functionality
        if ($TempInput -ne $Input) { 
            if ($Input.Length -gt 1) { $Remainder = $Input.Replace($TempInput,$NULL) }
            else { $Remainder = $Input }
            $UseTemp = $TRUE 
        }
        # No remainder required
        else { $UseTemp = $FALSE }

        # User Input
        $Key = $Host.UI.RawUI.ReadKey()

        # Backspace (Remove Character)
        if ($Key.VirtualKeyCode -eq '8') {
            # Remove last character of line (if input mark at end of line)
            if ($Input -and ($Input.Length -gt 1) -and (!$UseTemp)) { $Input = $Input.Substring(0,$Input.Length - 1) }

            # Remove last character of input buffer (if input mark NOT at end of line)
            elseif ($Input -and ($Input.Length -gt 1) -and ($UseTemp)) { 
                $TempInput = $TempInput.Substring(0,$TempInput.Length - 1)
                $Input = $TempInput + $Remainder
            }

            # Remove last character of line (if 1 character in line)
            elseif ($Input -and ($Input.Length -eq 1)) { $Input = $NULL }

            # Remove entire line / create new array from text contents (if 0 characters in line)
            else {
                $NewArray = @()

                # Append all but active line to new array
                for ($i=0; $i -lt $InputArray.Count; $i++) {
                    if ($i -ne $ArrayDir) { $NewArray += $InputArray[$i] }
                }

                $InputArray = $NewArray
                $Skip = $TRUE

                # Change active line
                if ($ArrayDir -gt 0) { $ArrayDir-- }
                $Input = $InputArray[$ArrayDir]
            }

            # Text Changes Visual Indicator
            $Changes = $TRUE
        }

        # Delete (Remove Line)
        elseif ($Key.VirtualKeyCode -eq '46') {
            ### Remove entire line / create new array from text contents
            $NewArray = @()

            # Append all but active line to new array
            for ($i=0; $i -lt $InputArray.Count; $i++) {
                if ($i -ne $ArrayDir) { $NewArray += $InputArray[$i] }
            }

            $InputArray = $NewArray
            $Skip = $TRUE

            # Change active line
            if ($ArrayDir -gt 0) { $ArrayDir-- }
            $Input = $InputArray[$ArrayDir]

            # Text Changes Visual Indicator
            $Changes = $TRUE
        }

        # Enter (New Line)
        elseif ($Key.VirtualKeyCode -eq '13') {
            # Save current input to active line, set null new line
            if (!$TempRemainder) {
                $InputArray[$ArrayDir] = $Input
                $Input = $NULL 
            }
            # Save preface to active line, send remainder to new line
            else {
                $InputArray[$ArrayDir] = $TempInput
                $Input = $TempRemainder 
            }

            $NewArray = @()
            for ($i=0; $i -lt $InputArray.Count; $i++) {
                # Append non-active lines to new array
                if ($i -ne $ArrayDir) { $NewArray += $InputArray[$i] }

                # Append empty input line to new array
                else {
                    $NewArray += $InputArray[$i]
                    $NewArray += $Input 
                }
            }

            # Reset input mark
            $CharDir = -1

            $InputArray = $NewArray
            $Skip = $TRUE
            $ArrayDir++

            # Text Changes Visual Indicator
            $Changes = $TRUE
        }


        ### Relative Char Position via Reverse Char Index:        Position = (Line Length + 1) + Character Index
        ### New Reverse Char Index via Relative Char Position:    Character Index = Position - (Line Length + 1)

        # Note: 
        # This arbitrary formula was created because I used reverse indexes for character positions (e.g., $Line[-1])
        # and needed a mathematical way to determine index depth despite varying line lengths in order to get the 
        # left and right arrow key functionality to work properly.


        # Arrow Key Up (Change Active Line)
        elseif ($Key.VirtualKeyCode -eq '38') {
            
            # Establish current relative character position
            $Position = ($InputArray[$ArrayDir].Length + 1) + $CharDir

            # Decrement Active Line / Loop to Last Line
            if ($ArrayDir -ne 0) { $ArrayDir-- }
            else { $ArrayDir = ($InputArray.Count - 1) }

            # Establish new reverse character position
            if (($Position -gt ($InputArray[$ArrayDir]).Length - 1) -or ($CharDir -eq -1)) { $CharDir = -1 }
            else { $CharDir = $Position - ($InputArray[$ArrayDir].Length + 1) }

            # Set input to new active line
            $Input = $InputArray[$ArrayDir]
        }

        # Arrow Key Down (Change Active Line)
        elseif ($Key.VirtualKeyCode -eq '40') {

            # Establish current relative character position
            $Position = ($InputArray[$ArrayDir].Length + 1) + $CharDir

            # Increment Active Line / Loop to First Line
            if ($ArrayDir -ne ($InputArray.Count - 1)) { $ArrayDir++ }
            else { $ArrayDir = 0 }

            # Establish new reverse character position
            if (($Position -gt ($InputArray[$ArrayDir]).Length - 1) -or ($CharDir -eq -1)) { $CharDir = -1 }
            else { $CharDir = $Position - ($InputArray[$ArrayDir].Length + 1) }

            # Set input to new active line
            $Input = $InputArray[$ArrayDir]
        }

        # Arrow Key Left (Change Active Character)
        elseif ($Key.VirtualKeyCode -eq '37') {
            $ActiveLine = $InputArray[$ArrayDir]

            # Decrement Reverse Character Position / Loop to End of Line
            if ($CharDir -gt (-$ActiveLine.Length - 1)) { $CharDir-- }
            else { $CharDir = -1 }
        }

        # Arrow Key Right (Change Active Character)
        elseif ($Key.VirtualKeyCode -eq '39') {
            $ActiveLine = $InputArray[$ArrayDir]

            # Increment Reverse Character Position / Loop to Beginning of Line
            if ($CharDir -lt -1) { $CharDir++ }
            else { $CharDir = (-$ActiveLine.Length - 1) }
        }

        # Left Alt (Save)
        elseif (($Key.VirtualKeyCode -eq '18') -and ($Key.ControlKeyState -like '*LeftAltPressed*')) {
            # Prompt for filename if not already set
            if (!$File) {
                if (!$newPath) { Write-Host "`nCurrent Directory: " -ForegroundColor Yellow -NoNewline ; Write-Host $PWD }
                Write-Host "Save as: " -ForegroundColor Yellow -NoNewline ; $TempFile = Read-Host
            }

            # Return to text page
            if ($TempFile -and ($TempFile -eq "back")) { $TempFile = $NULL; continue }
            # Append .txt if file extension not explicitly typed
            elseif ($TempFile -and ($TempFile -notlike "*.*")) { $File = $Tempfile + ".txt" }

            # Create absolute path of output file / save file
            if (!$FileOut) {
                if (!$newPath) { $FileOut = "$PWD\$File" }
                else { $FileOut = "$newPath\$File" }
            }

            [System.IO.File]::WriteAllLines($FileOut, $InputArray)

            # Clear screen / Imitated Graceful Exit
            Clear-Host
            Write-Host "PS $PWD> vim $File"

            # Verify File Creation
            if (Test-Path -LiteralPath $FileOut) { Write-Host "File successfully saved." -ForegroundColor DarkGreen }
            else { Write-Host "File failed to save." -ForegroundColor DarkRed }

            # Exit PseudoVym
            return
        }

        # Right Alt (Quit)
        elseif (($Key.VirtualKeyCode -eq '18') -and ($Key.ControlKeyState -like '*RightAltPressed*')) {
            # Clear screen / Imitated Graceful Exit
            Clear-Host
            Write-Host "PS $PWD> vim $File"

            # Display if exited without saving changes or no changes needed to be saved
            if ($Changes) { Write-Host "Exited without saving." -ForegroundColor Yellow }
            else { Write-Host "Exited PseudoVym." -ForegroundColor Yellow }

            # Exit PseudoVym
            return 
        }
        
        # Control (Developer Console)
        elseif ($Key.VirtualKeyCode -eq "17") { $File, $NewPath, $ConsoleExit = Vim-DevConsole }

        # Special Keys to Ignore
        elseif ($Stinky -contains $Key.VirtualKeyCode) { $Skip = $TRUE }

        # Valid Characters
        else {
            # Append character to end of line
            if (!$UseTemp) { $Input += $Key.Character }

            # Append character to input buffer
            else { 
                $TempInput += $Key.Character
                $Input = $TempInput + $Remainder
            }

            # Text Changes Visual Indicator
            $Changes = $TRUE
        }
    }
}
