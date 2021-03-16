function PseudoVym {
#.SYNOPSIS
# Rudimentary PowerShell variant of Vim.
# ARBITRARY VERSION NUMBER:  2.9.3
# AUTHOR:  Tyler McCann (@tyler.rar)
#
#.DESCRIPTION
# Simple script that aims to bring some Vim functionality to PowerShell, since Windows / PowerShell does
# not have a native CLI text editor. If a filename is input without a file extension, '.txt' will be
# appended to the file (with the Developer Console being an exception; a file extension must be input in
# the console).  File contents will be adjusted accordingly with current terminal window height.
#
# Supports alternate data streams (ADS) and secure shell (SSH).
#
# Recommendations:
# -- Use 'Vim.psm1' (and included instructions) from the repo to load this script from your $PROFILE.
# -- Use the 'vim' alias rather than 'PseudoVym' for efficiency.
#
# Parameters:
#    -File          -->    (Optional) Input/output file
#    -Debug         -->    (Optional) Display position and input info    
#    -LegacyKeys    -->    (Optional) Enable original key configuration (L/R Alt + Ctrl)
#    -Help          -->    (Optional) Return Get-Help info
#
# Special Keys:
#    F1             -->    Save and quit
#    F2             -->    Quit
#    F3             -->    Developer console
#    Delete         -->    Remove entire line
#    Page Up        -->    Jump to first line
#    Page Down      -->    Jump to last line
#    L Alt          -->    Save and quit      (Legacy / Not SSH Compatible)
#    R Alt          -->    Quit               (Legacy / Not SSH Compatible)
#    Ctrl           -->    Developer console  (Legacy / Not SSH Compatible)
#
# Developer Console:
#    help           -->    List available commands
#
# Debug Mode:
#    Preface        -->    Content BEFORE user input
#    Remainder      -->    Content AFTER user input
#    CharIndex      -->    Reverse character index
#    LineIndex      -->    Currently active line
#    OutputSize     -->    Number of lines currently printed
#    WindowSize     -->    Maximum number of lines in window
#    ExecTime       -->    Execution time in milliseconds
#
# "Save as:" Prompts:
#    back           -->    Exit from prompt
#
#.LINK
# https://github.com/tylerdotrar/PseudoVym

    [Alias('vim')]

    Param (
        [string] $File,
        [switch] $Debug,
        [switch] $LegacyKeys,
        [switch] $Help
    )

    $VersionNumber = 'v2.9.3'

    # Live Visual Formatting of Text
    function Vim-Formatting ([switch]$DevConsole) {

        function Line-Printing ([int]$FirstLine) {

            # Format spacing in front of text (2)
            $Length = $MaxLength - ($IndexLine | Measure-Object -Character).characters
            $Space = " " * $Length

            # Contents of the iterated line
            $Line = $InputArray[$IndexLine]

            # Debug banner
            if ($Debug -and $IndexLine -eq $FirstLine) { Write-Host "Debug Mode:`n$Delim`n" }

            # If iterated line is the active line
            if ($IndexLine -eq $ArrayDir) {
                $VisualInput = $NULL
                $Remainder = $NULL
                Write-Host "$IndexLine$Space" -ForegroundColor Red -NoNewline

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
            else { Write-Host "$IndexLine$Space" -ForegroundColor Yellow -NoNewline ; Write-Host $Line }

            return $VisualInput, $DebugRemainder
        }

        <#
        Note:
        Text will not properly display if...
          -- Window height is less than 6 lines (w/o Debug)
          -- Window height is less than 19 lines (w/ Debug)
        #>

        # Calculate / update window and input heights
        $MaxTerminalHeight = $Host.UI.RawUI.WindowSize.Height
        $OutputHeight = $InputArray.Count

        if ($CustomPath -or $Debug) { $HeaderHeight = 7 }
        else { $HeaderHeight = 6 }

        if ($Debug) { $DebugHeight = 12 }
        else { $DebugHeight = 0 }
        
        # Amount of lines currently being printed
        $TotalHeight = $HeaderHeight + $OutputHeight + $DebugHeight


        # Time taken to print all output to screen
        $DebugTime = Measure-Command {

            ### Header formatting

            # Version Number
            Write-Host "PseudoVym " -ForegroundColor Yellow -NoNewline ; Write-Host "($VersionNumber)"

            # Output path
            if ($Debug -or $CustomPath) {
                Write-Host "Output Path: " -ForegroundColor Yellow -NoNewline

                if ($CustomPath) { Write-Host "$CustomPath" }
                else { Write-Host "$PWD" }
            }

            # Active Filename
            Write-Host "Filename: " -ForegroundColor Yellow -NoNewline

            if ($File) {
                if ($Changes) { Write-Host "$File" -NoNewLine ; Write-Host "*" -ForegroundColor Red }
                else { Write-Host "$File" }
            }

            else {
                if ($Changes) { Write-Host "N/A" -NoNewLine ; Write-Host "*" -ForegroundColor Red }
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

            # Print every line of text
            if ($TotalHeight -le $MaxTerminalHeight) {

                for ($IndexLine = 0; $IndexLine -lt $InputArray.Count; $IndexLine++) {
                    $VisualInput, $DebugRemainder = Line-Printing -FirstLine 0
                    $VisualLimits = @()
                }
            }

            # Print lines to current window size
            else {
                $Difference = ($TotalHeight - $MaxTerminalHeight) - 1

                # Active line within window size limits
                if ($VisualLimits -contains $ArrayDir) {

                    for ($IndexLine = $VisualLimits[0]; $IndexLine -le $VisualLimits[-1]; $IndexLine++) {
                        
                        $VisualInput, $DebugRemainder = Line-Printing -FirstLine $VisualLimits[0]
                    }
                }

                # Adjust limits (PAGE CONTENTS DOWN)
                elseif ($ArrayDir -ge $Difference) {

                    for ($IndexLine = $Difference; $IndexLine -lt $InputArray.Count; $IndexLine++) {
                        
                        $VisualInput, $DebugRemainder = Line-Printing -FirstLine $Difference
                    }
                    $VisualLimits = $Difference..($InputArray.Count - 1)
                }

                # Adjust limits (INCREMENT CONTENTS UP)
                else {
                    $IndexOffset = ($Difference - $ArrayDir)

                    for ($IndexLine = $ArrayDir; $IndexLine -lt ($InputArray.Count - $IndexOffset); $IndexLine++) {
                        
                        $VisualInput, $DebugRemainder = Line-Printing -FirstLine $ArrayDir
                    }
                    $VisualLimits = $ArrayDir..($InputArray.Count - $IndexOffset - 1)
                }
            }

            # Useful debug info
            if ($Debug) {
                if ($MaxTerminalHeight -lt 19) { $WindowMsg = "[ERROR: MINIMUM 19]" }
                else { $WindowMsg = $NULL }

                Write-Host "`n$Delim"
                Write-Host "Preface     " -NoNewline ; Write-Host "-->  " -ForegroundColor Red -NoNewline ; Write-Host "'$VisualInput'"
                Write-Host "Remainder   " -NoNewline ; Write-Host "-->  " -ForegroundColor Red -NoNewline ; Write-Host "'$DebugRemainder'"
                Write-Host "CharIndex   " -NoNewline ; Write-Host "-->  " -ForegroundColor Red -NoNewline ; Write-Host "$CharDir"
                Write-Host "LineIndex   " -NoNewline ; Write-Host "-->  " -ForegroundColor Red -NoNewline ; Write-Host "$ArrayDir"
                Write-Host "OutputSize  " -NoNewline ; Write-Host "-->  " -ForegroundColor Red -NoNewline ; Write-Host "$TotalHeight lines"
                Write-Host "WindowSize  " -NoNewline ; Write-Host "-->  " -ForegroundColor Red -NoNewline ; Write-Host "$MaxTerminalHeight lines " -NoNewline ; Write-Host $WindowMsg -ForegroundColor Red
                Write-Host "ExecTime    " -NoNewline ; Write-Host "-->  " -ForegroundColor Red -NoNewline
            }
        }
        if ($Debug) { Write-Host $DebugTime.TotalMilliseconds ms }

        Write-Host ""

        # Returned to create a buffer, allowing for left/right arrow key functionality
        if (!$DevConsole) { return $VisualInput, $DebugRemainder, $VisualLimits }
    }

    # Developer Console
    function Vim-DevConsole {
        
        function Terminal-Printing ([string]$Command) {

            if ($Command -eq "[Redacted]") { Write-Host $Command -ForegroundColor Yellow }
            elseif (($GreenOutput -contains $Command) -or ($Command -like "Line(s):*")) { Write-Host $Command -ForegroundColor Green }
            elseif ($RedOutput -contains $Command) { Write-Host $Command -ForegroundColor Red }
            else { Write-Host $Command }
        }

        $GreenOutput = "File saved.", "Output path saved.", "Filename saved.", "Debugger enabled.", "Legacy keys enabled."
        $RedOutput = "Invalid input.", "Debugger disabled.", "No match(es) found.", "Invalid index.", "Legacy keys disabled."
        $TerminalOutput = @()
        
        while ($TRUE) {
            
                Clear-Host
                Vim-Formatting -DevConsole
                Write-Host "--"

            # Update text information and display ONLY the last 10 console entries
            if (!$SkipRefresh) {

                # Display all console output
                if ($TerminalOutput.Count -lt 7) { 
                    foreach ($TerminalLine in $TerminalOutput) {

                        Terminal-Printing -Command $TerminalLine
                    }
                }

                # Display the last 14 console outputs
                else { 
                    for ($i = $TerminalOutput.Count - 7; $i -lt $TerminalOutput.Count; $i++) {

                        Terminal-Printing -Command $TerminalOutput[$i]
                    }
                }
            }

            # Display help information
            else {
                Write-Host ":" -ForegroundColor Yellow -NoNewline; Write-Host $DevOption

                Write-Host "  w" -ForegroundColor Yellow -NoNewline ; Write-Host "               -->  Save"
                Write-Host "  q" -ForegroundColor Yellow -NoNewline ; Write-Host "               -->  Quit"
                Write-Host "  wq" -ForegroundColor Yellow -NoNewLine ; Write-Host "              -->  Save and Quit"
                Write-Host "  set file=*" -ForegroundColor Yellow -NoNewLine ; Write-Host "      -->  Output Filename"
                Write-Host "  set path=*" -ForegroundColor Yellow -NoNewline ; Write-Host "      -->  Output Directory"
                Write-Host "  find=*" -ForegroundColor Yellow -NoNewLine ; Write-Host "          -->  Search for String"
                Write-Host "  jump=*" -ForegroundColor Yellow -NoNewLine ; Write-Host "          -->  Change Active Line"
                Write-Host "  dbg" -ForegroundColor Yellow -NoNewLine ; Write-Host "             -->  Toggle Debugger"
                Write-Host "  legacy" -ForegroundColor Yellow -NoNewLine ; Write-Host "          -->  Toggle Legacy Keys"
                Write-Host "  cls" -ForegroundColor Yellow -NoNewline ; Write-Host "             -->  Clear Screen"
                Write-Host "  :" -ForegroundColor Yellow -NoNewline ; Write-Host "               -->  Exit Developer Console"
            }

            $SkipRefresh = $FALSE

            # User input
            Write-Host ":" -ForegroundColor Yellow -NoNewline ; $DevOption = Read-Host
            $TerminalOutput += ":$DevOption"

            # List available commands
            if ($DevOption -eq "help") {
                $TerminalOutput += "[Redacted]"
                $SkipRefresh = $TRUE
            }

            # Save
            elseif ($DevOption -eq "w") {
                while ($TRUE) {
                    # Prompt for filename if not already set
                    if (!$File) { 
                        $TempFile = Read-Host "Save as"

                        $TerminalOutput += "Save as: $TempFile"
                    }

                    if ($TempFile) {
                        # Return to developer console without saving
                        if ($TempFile -eq "back") { break }

                        # Error correction
                        elseif ($TempFile -notlike "*.*") {
                            $TerminalOutput += "Invalid input."

                            Write-Host $TerminalOutput[-1] -ForegroundColor Red
                        }

                        else { $File = $TempFile ; $TempFile = $NULL }
                    }

                    # Save file
                    else {

                        # Set output file path to current directory or user input directory (set path=*)
                        if (!$CustomPath) { $FileOut = "$PWD\$File" }
                        else {
                            if (!(Test-Path -LiteralPath $CustomPath 2>$NULL)) { New-Item -Path $CustomPath -ItemType Directory | Out-Null }

                            $FileOut = "$CustomPath\$File"
                        }

                        # Save file, Remove Text Change Visual Indicator, Return to Console

                        # Slight improvement for desktop PowerShell ADS.
                        if ((!$PwshBool) -and ($File -like '*:*')) { Set-Content -Value $InputArray -LiteralPath "$FileOut" }
                        else { [System.IO.File]::WriteAllLines($FileOut, $InputArray) }

                        $TerminalOutput += "File saved."
                        $Changes = $FALSE
                        break
                    }
                }
            }

            # Quit PseudoVym
            elseif ($DevOption -eq "q") {
                Clear-Host
                $ConsoleExit = $TRUE

                return $File, $CustomPath, $Changes, $Debug, $ConsoleExit, $ArrayDir, $LineInput, $LegacyKeys
            }

            # Save and Quit
            elseif ($DevOption -eq "wq") {
                while ($TRUE) {
                    # Prompt for filename if not already set
                    if (!$File) { 
                        $TempFile = Read-Host "Save as"

                        $TerminalOutput += "Save as: $TempFile"
                    }

                    if ($TempFile) {
                        # Return to developer console without saving
                        if ($TempFile -eq "back") { break }

                        # Error correction
                        elseif ($TempFile -notlike "*.*") {
                            $TerminalOutput += "Invalid input."

                            Write-Host $TerminalOutput[-1] -ForegroundColor Red
                        }

                        else { $File = $TempFile ; $TempFile = $NULL }
                    }

                    # Save file
                    else {

                        # Set output file path to current directory or user input directory (set path=*)
                        if (!$CustomPath) { $FileOut = "$PWD\$File" }
                        else {
                            if (!(Test-Path -LiteralPath $CustomPath 2>$NULL)) { New-Item -Path $CustomPath -ItemType Directory | Out-Null }

                            $FileOut = "$CustomPath\$File"
                        }

                        # Save file and Exit PseudoVym

                        # Slight improvement for desktop PowerShell ADS.
                        if ((!$PwshBool) -and ($File -like '*:*')) { Set-Content -Value $InputArray -LiteralPath "$FileOut" }
                        else { [System.IO.File]::WriteAllLines($FileOut, $InputArray) }

                        Clear-Host
                        $ConsoleExit = $TRUE
                        return $File, $CustomPath, $Changes, $Debug, $ConsoleExit, $ArrayDir, $LineInput, $LegacyKeys
                    }
                }
            }

            # Return to text contents
            elseif ($DevOption -eq ":") { return $File, $CustomPath, $Changes, $Debug, $ConsoleExit, $ArrayDir, $LineInput, $LegacyKeys }

            # Set output file directory (use absolute path)
            elseif (($DevOption -like "set path=*") -and ($DevOption -notlike "*.*") -and ($DevOption -like "set path=*:\*")) {

                $TempPath = $DevOption.Replace("set path=",$NULL).Replace("'",$NULL).Replace('"',$NULL)
                if ($TempPath -match '\\$') { $TempPath = $TempPath.Substring(0,$TempPath.Length-1) }

                if ($TempPath -ne $PWD) { $CustomPath = $TempPath }
                $TerminalOutput += "Output path saved."
            }

            # Set filename (useful for copying files)
            elseif (($DevOption -like "set file=*") -and ($DevOption -like "*.*")) {

                $File = $DevOption.Replace("set file=",$NULL).Replace("'",$NULL).Replace('"',$NULL)
                $TerminalOutput += "Filename saved."
            }

            # Search Functionality
            elseif ($DevOption -like "find=*") {
                $FindString = $DevOption.Replace("find=",$NULL).Replace("'",$NULL).Replace('"',$NULL)

                $StringMatches = $InputArray | ?{$_ -like "*$FindString*"}

                if ($StringMatches){
                    #$TerminalOutput += "Match found."

                    $MatchedLines = @()
                    foreach ($StringMatch in $StringMatches) {
                        $MatchedLines += $InputArray.IndexOf($StringMatch)
                    }
                    $TerminalOutput += "Line(s): " + ($MatchedLines -join ",") 
                }
                else { $TerminalOutput += "No match(es) found." }

            }

            # Jump to Specific Lines
            elseif ($DevOption -like "jump=*") {
                $ProposedIndex = $DevOption.Replace("jump=",$NULL).Replace("'",$NULL).Replace('"',$NULL) -as [int]

                if ($ProposedIndex -and ($ProposedIndex -lt ($InputArray.Count)) -and ($ProposedIndex -ge 0)) {
                    $LineInput = $InputArray[$ProposedIndex]
                    return $File, $CustomPath, $Changes, $Debug, $ConsoleExit, $ProposedIndex, $LineInput
                }
                else { $TerminalOutput += "Invalid index."}
            }

            # Toggle Debugger
            elseif ($DevOption -eq "dbg") { 
                $Debug = !$Debug

                if ($Debug) { $TerminalOutput += "Debugger enabled." }
                else { $TerminalOutput += "Debugger disabled." }
            }

            # Toggle Legacy Keys
            elseif ($DevOption -eq "legacy") {
                $LegacyKeys = !$LegacyKeys

                if ($LegacyKeys) { $TerminalOutput += "Legacy keys enabled." }
                else { $TerminalOutput += "Legacy keys disabled." }
            }

            # Clear console screen
            elseif ($DevOption -eq "cls") { $TerminalOutput = @() }

            # Error correction
            else { $TerminalOutput += "Invalid input." }
        }
    }

    # Key Functionality for ArrowUp, ArrowDown, PageUp, and PageDown
    function Change-ActiveLine ([switch]$ArrowUp, [switch]$ArrowDown, [switch]$PageUp, [switch]$PageDown) {

        # Establish current relative character position
        $Position = ($InputArray[$ArrayDir].Length + 1) + $CharDir

        if ($ArrowUp) {

            # Decrement Active Line / Loop to Last Line
            if ($ArrayDir -ne 0) { $ArrayDir-- }
            else { $ArrayDir = ($InputArray.Count - 1) }

        }
        elseif ($ArrowDown) {
            
            # Increment Active Line / Loop to First Line
            if ($ArrayDir -ne ($InputArray.Count - 1)) { $ArrayDir++ }
            else { $ArrayDir = 0 }

        }
        elseif ($PageUp) { $ArrayDir = 0 }

        elseif ($PageDown) { $ArrayDir = ($InputArray.Count - 1) }

        # Establish new reverse character position
        if (($Position -gt ($InputArray[$ArrayDir]).Length - 1) -or ($CharDir -eq -1)) { $CharDir = -1 }
        else { $CharDir = $Position - ($InputArray[$ArrayDir].Length + 1) }

        # Set input to new active line
        $LineInput = $InputArray[$ArrayDir]

        return $ArrayDir, $CharDir, $LineInput
    }

    # Key Functionality for ArrowLeft and ArrowRight
    function Change-ActiveChar ([switch]$ArrowLeft, [switch]$ArrowRight) {

        $ActiveLine = $InputArray[$ArrayDir]

        if ($ArrowLeft) {
            
            # Decrement Reverse Character Position / Loop to End of Line
            if ($CharDir -gt (-$ActiveLine.Length - 1)) { $CharDir-- }
            else { $CharDir = -1 }

        }
        elseif ($ArrowRight) {

            # Increment Reverse Character Position / Loop to Beginning of Line
            if ($CharDir -lt -1) { $CharDir++ }
            else { $CharDir = (-$ActiveLine.Length - 1) }

        }

        return $CharDir
    }

    # VirtualKeyCodes:
    $Backspace   = 8
    $Tab         = 9
    $Enter       = 13
    $Shift       = 16
    $CapsLock    = 20
    $Escape      = 27
    $PageUp      = 33
    $PageDown    = 34
    $EndKey      = 35
    $HomeKey     = 36
    $ArrowLeft   = 37
    $ArrowUp     = 38
    $ArrowRight  = 39
    $ArrowDown   = 40
    $Insert      = 45
    $Delete      = 46
    $F1          = 112
    $F2          = 113
    $F3          = 114
    $FuncKeys    = 115..123

    # Keys to be Ignored by User Input
    $Stinky = $Shift, $CapsLock, $Escape, $EndKey, $HomeKey, $Insert, $FuncKeys, 17, 18

    # PowerShell version detection
    if ($PSEdition -eq 'Core') { $PwshBool = $TRUE }

    # Return help info
    if ($Help) { return Get-Help PseudoVym }

    # Load and format existing file
    if ($File -and (Test-Path -LiteralPath $File 2>$NULL)) {
        
        # ADS Support (Part 1)
        if ((Get-Item -LiteralPath $File).PSChildName -like "*:*") {

            $ADSfile = ((Get-Item -LiteralPath $File).PSChildName -split ':')[0]
            $ADSPath = (Get-Item -LiteralPath $File).FileName -replace "$ADSfile","$NULL"
            $ParentPath = $ADSPath.Substring(0,$ADSPath.Length - 1)
        }

        # Normal file
        else {
            
            $FullPath = (Get-Item $File).FullName
            $ParentPath = Split-Path $FullPath -Parent
        }

        $File = Split-Path $File -Leaf
        if ($ParentPath -ne $PWD) { $CustomPath = $ParentPath }
        
        # ADS Support (Part 2)
        $BigFile = "$ParentPath\$File"

        $Skip = $TRUE
        $InputArray = @()
        $LineCount = 0

        foreach ($Line in (Get-Content -LiteralPath $BigFile)) {
            $InputArray += $Line
            $LineCount++
        }

        $ArrayDir = ($LineCount - 1)
        $LineInput = $InputArray[$ArrayDir]
        $CharDir = -1
    }

    # Start new file
    else {

        if ($File) {
            
            # Append .txt if file extension not explicitly stated.
            if ($File -like ".\*") { $File = $File.Replace(".\",$NULL) }
            if ($File -notlike "*.*") { $File = $File + ".txt" }
            $Changes = $TRUE
        }

        $LineInput = $NULL
        $ArrayDir = 0
        $CharDir = -1
    }
    

    # Start MAIN
    $Refresh = $TRUE
    while ($TRUE) {

        # Refresh screen every time there is valid input
        if ($Refresh) { Clear-Host }

        # Exit PseudoVym via Developer Console
        if ($ConsoleExit) { return }

        # Toggle Legacy Keys
        if ($LegacyKeys) { $Ctrl = 17; $Alt = 18 }
        else { $Ctrl = $NULL; $Alt = $NULL}

        # Initialize input / Update selected line with new input
        if (!$Skip) {
            if (!$InputArray) { $InputArray = @("$LineInput") }
            else { $InputArray[$ArrayDir] = $LineInput }
        }
        $Skip = $FALSE

        # Call visual formatting function / create input and remainder buffers
        if ($Refresh) { $TempInput, $TempRemainder, $VisualLimits = Vim-Formatting }
        $Refresh = $TRUE

        # Create File output path
        if ($File) {
            if (!$CustomPath) { $FileOut = "$PWD\$File" }
            else { $FileOut = "$CustomPath\$File" }
        }

        # Establish remainder for left/right arrow key functionality
        if ($TempInput -ne $LineInput) {

            if ($LineInput.Length -gt 1) { $Remainder = $LineInput.Replace($TempInput,$NULL) }
            else { $Remainder = $LineInput }
            $UseTemp = $TRUE
        }

        # No remainder required
        else { $UseTemp = $FALSE }

        # User Input
        $Key = $Host.UI.RawUI.ReadKey()

        switch ($Key.VirtualKeyCode) {

            # Remove Character
            $Backspace
                {
                    if ($LineInput) {
                        if ($LineInput.Length -gt 1) {

                            # Remove last character of line (if input mark at end of line)
                            if (!$UseTemp) { $LineInput = $LineInput.Substring(0,$LineInput.Length - 1) }

                            # Remove last character of input buffer (if input mark NOT at end of line)
                            else {
                                $TempInput = $TempInput.Substring(0,$TempInput.Length - 1)
                                $LineInput = $TempInput + $Remainder
                            }
                        }

                        # Remove last character of line (if 1 character in line)
                        elseif ($LineInput.Length -eq 1) { $LineInput = $NULL }
                    }

                    # Remove entire line / create new array from text contents (if 0 characters in line)
                    else {
                        $NewArray = @()

                        # Append all but active line to new array
                        for ($i=0; $i -lt $InputArray.Count; $i++) {
                            if ($i -ne $ArrayDir) { $NewArray += $InputArray[$i] }
                        }

                        # Fix temporary null input if first line is removed
                        if ($NewArray.Count -eq 0) {
                            $Refresh = $FALSE
                            $InputArray = @("$LineInput")
                        }
                        else { $InputArray = $NewArray }

                        $Skip = $TRUE

                        # Change active line
                        if ($ArrayDir -gt 0) { $ArrayDir-- }
                        $LineInput = $InputArray[$ArrayDir]
                    }

                    # Text Changes Visual Indicator
                    $Changes = $TRUE
                }


            # Remove Line
            $Delete
                {
                    # Fix temporary null input if first line is removed
                    if ($InputArray.Count -eq 1) {
                        # Text Changes Visual Indicator
                        $Changes = $TRUE
                        $LineInput = $NULL
                    }
                    else {
                        # Remove entire line / create new array from text contents
                        $NewArray = @()

                        # Append all but active line to new array
                        for ($i=0; $i -lt $InputArray.Count; $i++) {
                            if ($i -ne $ArrayDir) { $NewArray += $InputArray[$i] }
                        }

                        $InputArray = $NewArray
                        $Skip = $TRUE

                        # Change active line
                        if ($ArrayDir -gt 0) { $ArrayDir-- }
                        $LineInput = $InputArray[$ArrayDir]

                        # Text Changes Visual Indicator
                        $Changes = $TRUE
                    }
                }


            # New Line
            $Enter
                {
                    # Save current input to active line, set null new line
                    if (!$TempRemainder) {
                        $InputArray[$ArrayDir] = $LineInput
                        $LineInput = $NULL
                    }
                    # Save preface to active line, send remainder to new line
                    else {
                        $InputArray[$ArrayDir] = $TempInput
                        $LineInput = $TempRemainder
                    }

                    $NewArray = @()
                    for ($i=0; $i -lt $InputArray.Count; $i++) {
                        # Append non-active lines to new array
                        if ($i -ne $ArrayDir) { $NewArray += $InputArray[$i] }

                        # Append empty input line to new array
                        else {
                            $NewArray += $InputArray[$i]
                            $NewArray += $LineInput
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


            <#
            ++ Relative Char Position via Reverse Char Index:        Position = (Line Length + 1) + Character Index
            ++ Reverse Char Index via Relative Char Position:        Character Index = Position - (Line Length + 1)

            Note:
            This arbitrary formula was created because I used reverse indexes for character positions (e.g., $Line[-1])
            and needed a mathematical way to determine index depth despite varying line lengths in order to get the
            left and right arrow key functionality to work properly.
            #>


            # Change Active Line (Up)
            $ArrowUp
                {
                    $ArrayDir, $CharDir, $LineInput = Change-ActiveLine -ArrowUp
                }


            # Change Active Line (Down)
            $ArrowDown
                {
                    $ArrayDir, $CharDir, $LineInput = Change-ActiveLine -ArrowDown
                }


            # Change Active Line (Top)
            $PageUp
                {
                    $ArrayDir, $CharDir, $LineInput = Change-ActiveLine -PageUp
                }

            
            # Change Active Line (Bottom)
            $PageDown
                {
                    $ArrayDir, $CharDir, $LineInput = Change-ActiveLine -PageDown
                }

            # Change Active Character (Left)
            $ArrowLeft
                {
                    $CharDir = Change-ActiveChar -ArrowLeft
                }


            # Change Active Character (Right)
            $ArrowRight
                {
                    $CharDir = Change-ActiveChar -ArrowRight
                }

            
            # Save and Quit (SSH Compatible)
            $F1
                {
                    # Prompt for filename if not already set
                    if (!$File) {
                        if (!$CustomPath) { Write-Host "`nCurrent Directory: " -ForegroundColor Yellow -NoNewline ; Write-Host $PWD }
                        Write-Host "Save as: " -ForegroundColor Yellow -NoNewline ; $TempFile = Read-Host
                    }

                    if ($TempFile) {
                        # Return to text page
                        if ($TempFile -eq "back") { $TempFile = $NULL; continue }

                        else {
                            # Append .txt if file extension not explicitly typed
                            if ($TempFile -notlike "*.*") { $File = $Tempfile + ".txt" }
                            else { $File = $TempFile }

                            $TempFile = $NULL
                        }
                    }

                    # Create absolute path of output file / save file
                    if (!$FileOut) {
                        if (!$CustomPath) { $FileOut = "$PWD\$File" }
                        else { $FileOut = "$CustomPath\$File" }
                    }

                    # Slight improvement for desktop PowerShell ADS.
                    if ((!$PwshBool) -and ($File -like '*:*')) { Set-Content -Value $InputArray -LiteralPath "$FileOut" }
                    else { [System.IO.File]::WriteAllLines($FileOut, $InputArray) }

                    # Clear screen / Imitated Graceful Exit
                    Clear-Host
                    if ($CustomPath) { Write-Host "PS $PWD> vim $CustomPath\$File" }
                    elseif ($File) { Write-Host "PS $PWD> vim .\$File" }
                    else { Write-Host "PS $PWD> vim" }

                    # Verify File Creation
                    if (Test-Path -LiteralPath $FileOut 2>$NULL) { Write-Host "File successfully saved." -ForegroundColor Green }
                    else { Write-Host "File failed to save." -ForegroundColor Red }

                    # Exit PseudoVym
                    return
                }


            # Quit (SSH Compatible)
            $F2
                {
                    # Clear screen / Imitated Graceful Exit
                    Clear-Host
                    if ($CustomPath) { Write-Host "PS $PWD> vim $CustomPath\$File" }
                    elseif ($File) { Write-Host "PS $PWD> vim .\$File" }
                    else { Write-Host "PS $PWD> vim" }

                    # Display if exited without saving changes or no changes needed to be saved
                    if ($Changes) { Write-Host "Exited PseudoVym without saving." -ForegroundColor Yellow }
                    else { Write-Host "Exited PseudoVym." -ForegroundColor Yellow }

                    # Exit PseudoVym
                    return
                }


            # Developer Console
            $F3 { $File, $CustomPath, $Changes, $Debug, $ConsoleExit, $ArrayDir, $LineInput, $LegacyKeys = Vim-DevConsole }


            # Save and/or Quit (Legacy / Not SSH Compatible)
            $Alt
                {
                    # Save and Quit
                    if (($Key.ControlKeyState -like '*LeftAltPressed*') -or ($Key.VirtualKeyCode -eq $F1)) {

                        # Prompt for filename if not already set
                        if (!$File) {
                            if (!$CustomPath) { Write-Host "`nCurrent Directory: " -ForegroundColor Yellow -NoNewline ; Write-Host $PWD }
                            Write-Host "Save as: " -ForegroundColor Yellow -NoNewline ; $TempFile = Read-Host
                        }

                        if ($TempFile) {
                            # Return to text page
                            if ($TempFile -eq "back") { $TempFile = $NULL; continue }

                            else {
                                # Append .txt if file extension not explicitly typed
                                if ($TempFile -notlike "*.*") { $File = $Tempfile + ".txt" }
                                else { $File = $TempFile }

                                $TempFile = $NULL
                            }
                        }

                        # Create absolute path of output file / save file
                        if (!$FileOut) {
                            if (!$CustomPath) { $FileOut = "$PWD\$File" }
                            else { $FileOut = "$CustomPath\$File" }
                        }

                        # Slight improvement for desktop PowerShell ADS.
                        if ((!$PwshBool) -and ($File -like '*:*')) { Set-Content -Value $InputArray -LiteralPath "$FileOut" }
                        else { [System.IO.File]::WriteAllLines($FileOut, $InputArray) }

                        # Clear screen / Imitated Graceful Exit
                        Clear-Host
                        if ($CustomPath) { Write-Host "PS $PWD> vim $CustomPath\$File" }
                        elseif ($File) { Write-Host "PS $PWD> vim .\$File" }
                        else { Write-Host "PS $PWD> vim" }

                        # Verify File Creation
                        if (Test-Path -LiteralPath $FileOut 2>$NULL) { Write-Host "File successfully saved." -ForegroundColor Green }
                        else { Write-Host "File failed to save." -ForegroundColor Red }

                        # Exit PseudoVym
                        return
                    }

                    # Quit
                    elseif (($Key.ControlKeyState -like '*RightAltPressed*') -or ($Key.VirtualKeyCode -eq $F1)) {

                        # Clear screen / Imitated Graceful Exit
                        Clear-Host
                        if ($CustomPath) { Write-Host "PS $PWD> vim $CustomPath\$File" }
                        elseif ($File) { Write-Host "PS $PWD> vim .\$File" }
                        else { Write-Host "PS $PWD> vim" }

                        # Display if exited without saving changes or no changes needed to be saved
                        if ($Changes) { Write-Host "Exited PseudoVym without saving." -ForegroundColor Yellow }
                        else { Write-Host "Exited PseudoVym." -ForegroundColor Yellow }

                        # Exit PseudoVym
                        return
                    }
                }


            # Developer Console (Legacy / Not SSH Compatible)
            $Ctrl { $File, $CustomPath, $Changes, $Debug, $ConsoleExit, $ArrayDir, $LineInput, $LegacyKeys = Vim-DevConsole }


            # Valid / Invalid Keys
            Default
                {
                    # Special Keys to Ignore
                    if ($Stinky -contains $Key.VirtualKeyCode) {
                        $Refresh = $FALSE
                        $Skip = $TRUE
                    }

                    # Valid Characters
                    else {
                        # Append character to end of line
                        if (!$UseTemp) { $LineInput += $Key.Character }

                        # Append character to input buffer
                        else {
                            $TempInput += $Key.Character
                            $LineInput = $TempInput + $Remainder
                        }

                        # Text Changes Visual Indicator
                        $Changes = $TRUE
                    }
                }
        }
    }
}