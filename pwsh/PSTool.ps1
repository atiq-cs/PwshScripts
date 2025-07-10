<#
.SYNOPSIS
  A powerscript to generate Problem solving source code template
.DESCRIPTION
  It's tedius to copy source file everytime and update info. Instead use a script to automate this.
  The template adhere to coding convention used in https://github.com/atiq-cs/Problem-Solving
  name situations for leetcode probably can be generated.
  ToDo:
  - Make independent .Net App to accomplish this
  - Add validation for template type i.e, not leetcode, codeforces etc.

.PARAMETER Template
  What kind of template do we want to generate, or which online judge we are targetting.
.PARAMETER Title
  Problem Title or Name: mandatory for codeforces to construct output file name
.PARAMETER Number
The problem number
- leetcode: used to construct file name only
- codeforces: used to construct file name and URL both
.PARAMETER URL
  Represents part of the URL (problem name) from a leetcod problem. Should be present for leetcode.
  ToDo: replace this with name construction from provided Name (Title)..
  ToDo: accept leetcode URL
  * probably it's intuitive just to extract info as much as possible from 
  This URL part is optional for codeforces problems. However, it will be used to construct file name
  if provided.

.PARAMETER Occasion
Won't be added to template if no provied. Usually to specify a contest or an event attended
related to the problem.
.PARAMETER Tags
Comma separated string containing tags
.PARAMETER JudgeStatus
Is it Accepted or WA or PE or CE by Judge.
.PARAMETER Force
Overwrite existing file if true.
.EXAMPLE
PSTool.ps1 open -Path general-solving/leetcode/0230_kth-smallest-element-in-a-bst.cs

It's probably a good idea to call last 3 params as named arguments
PSTool.ps1 -template leetcode -title 'First Unique Character in a String' -number 387 -tags @(`
  'string', 'hash-table')
PSTool.ps1 leetcode 'First Unique Character in a String' 387 @('string', 'hash-table')
To overwrite exist source file,
PSTool.ps1 leetcode 'First Unique Character in a String' 387 'string, hash-table'`
  first-unique-character-in-a-string -Force $true

Use for examining lintcode source files,
PSTool.ps1 -Command tempLintCmd -OutDirPath 015_permutation.cpp

.NOTES
Specify `OutDirPath` to modify destination where source file will be created. Currently, the script
requires to have suffix 'Problem-Solving'

more params can be added later if required
Probably implement opening file like,
  PSTool leetcode openfile 88

ref, error handling in Powershell
 https://blogs.msdn.microsoft.com/kebab/2013/06/09/an-introduction-to-error-handling-in-powershell/

ref, problem solving repo
 https://github.com/atiq-cs/Problem-Solving
#>
param(
  [string] $Command = 'GenerateTemplate',
  [string] $TemplateType,
  [string] $Title,
  [string] $Number,
  [string] $Tags,
  [string] $URL,
  [string] $JudgeStatus,
  [string] $Occasion,
  [string] $Path,
  [string] $OutDirPath = 'D:\Code\Problem-Solving',
    [bool] $Force = $false)

<#
.SYNOPSIS
Generates URL
.DESCRIPTION

.PARAMETER number
Comes from script arg
.PARAMETER url
url part is optional for codeforces
.EXAMPLE
GenerateTagList
#>
function GenerateURL() {
  switch ( $TemplateType ) {
    'leetcode' {
      if (! $URL) {
        throw [ArgumentException] 'URL is mandatory for leetcode template!'
      }
      return $URL
    }
    'codeforces' {
      # ToDo: verify number, because there is high prob of this being wrong..
      # throw [NotImplementedException] "todo for codeforces.."
      return $Number
    }
    default {
      $errorMessage = 'Template' + $TemplateType + ' is not supported yet!'
      throw [ArgumentException] $errorMessage
    }
  }
}

<#
.SYNOPSIS
Generate tags appended with 'tag-'
.DESCRIPTION
Not really a fan of semi-colon. But we keep it there for now.
Support 'tag-' in input string.
.PARAMETER tags
Comes from script arg.
* No space after comma is expected.
.EXAMPLE
GenerateTagList
#>
function GenerateTagList() {
  if ($Tags -match ';') {
    Write-Host -ForegroundColor Red 'Tags should be seperated with comman instead of semicolon!'
    exit
  }
  $tokens = $Tags.Split([char]',', [char]';')
  return 'tag-' + [string]::Join(', tag-', $tokens)
}

<#
.SYNOPSIS
Generate tags appended with 'tag-'
.DESCRIPTION
Not really a fan of semi-colon. But we keep it there for now.
.PARAMETER tags
Comes from script arg
.EXAMPLE
GenerateTagList
#>
function GenerateClassTemplate() {
  $codeStr = ''

  switch ( $TemplateType ) {
    'leetcode' {
      $className = 'Solution'
    }
    'codeforces' {
      $className = 'CFSolution'
    }
    default {
        Write-Host -ForegroundColor Red 'Template' $TemplateType ' is not supported yet!'
        exit
    }
  }
  $codeStr += 'public class ' + $className + [environment]::NewLine + '{' + [environment]::NewLine
  switch ( $TemplateType ) {
    'codeforces' {
      $codeStr += '  static void Main(String[] args) {' + [environment]::NewLine
      $codeStr += '    Demo demo = new Demo();' + [environment]::NewLine
      $codeStr += '    Demo.Run();' + [environment]::NewLine
      $codeStr += '  }' + [environment]::NewLine
    }
  }
  return $codeStr + '}'
}

<#
.SYNOPSIS
Generate output file name
.DESCRIPTION
need number (hence madatory)
need part url for leetcode. For codeforces, make that part of name from Title.
.PARAMETER tags
Comes from script arg
.EXAMPLE
GenerateTagList
#>
function GenerateOutputFileName() {
  $MaxLeetCodeNumLength = [int] 4

  if (! (Test-Path $OutDirPath -PathType Container)) {
    $errorMessage = "Specified output directory " + $OutDirPath + ' does not exist!'
    throw [ArgumentException] $errorMessage
    return $null
  }
  $outputFilePath = ''
  $defaultExt = '.cs'
  switch ( $TemplateType ) {
    'leetcode' {
      if (! $URL) {
        throw [ArgumentException] 'URL is mandatory for leetcode template!'
      }
      $absPath = $OutDirPath + '\' + 'general-solving\leetcode'
      if (! (Test-Path $absPath)) {
        $errorMessage = 'Absolute dir path: ' + $absPath + ' does not exist!'
        throw [ArgumentException] $errorMessage
      }
      $zeroString = '0' * [int] ($MaxLeetCodeNumLength - $Number.Length)
      $fName = $zeroString + $Number + '_' + $URL + $defaultExt
      $outputFilePath = $absPath + '\' + $fName
    }
    'codeforces' {
      # ToDo: verify number, because there is high prob of this being wrong..
      # throw [NotImplementedException] "todo for codeforces.."
      return $Number
    }
  }
  if (!$Force -And (Test-Path $outputFilePath)) {
    $errorMessage = 'File: ' + $fName + ' already exists!'
    throw [IO.IOException] $errorMessage
  }
  Write-Host "Creating source file" $outputFilePath "with" $TemplateType "template"
  return $outputFilePath
}


function GenerateTemplateCode() {
  <# Old way
  if (!(Test-Path $cpath)) {
    Write-Host "Creating File $cpath as it does not exist."
    "# Date: $(get-date)`n# Author: Atiq`n"> $cpath
  }#>

  # filename dynamic
  # exmaple
  # 0056_merge-intervals.cs
  # 626B_Cards.cs

  # URL
  # 

  # source file content
  $sFileContent = `
'/***************************************************************************************************'`
    + [environment]::NewLine
    
  # Title
  $sFileContent += '* Title : ' + $Title + [environment]::NewLine
  # generate URL
  $str = GenerateURL
  $sFileContent += '* URL   : ' + $str + [environment]::NewLine
  # Date
  $str = (Get-Date -UFormat %y-%m-%d)
  $sFileContent += '* Date  : ' + $str + [environment]::NewLine

  # Occasion
  # this way, because we might support more contest supported judges such as hackerrank
  switch ( $TemplateType ) {
    'codeforces' { $sFileContent += '* Occasn:' + $Occasion + [environment]::NewLine }
  }
  # Author
  $str = 'Atiq Rahman'
  $sFileContent += '* Author: ' + $str + [environment]::NewLine
  # Complexity
  $str = 'O()'
  $sFileContent += '* Comp  : ' + $str + [environment]::NewLine

  # Judge Status
  $str = $(if ($JudgeStatus) { $JudgeStatus } else { 'Accepted' })
  $sFileContent += '* Status: ' + $str + [environment]::NewLine
  # Notes
  $sFileContent += '* Notes : ' + [environment]::NewLine
  # ref and rel
  $sFileContent += '* ref   : ' + [environment]::NewLine
  $sFileContent += '* rel   : ' + [environment]::NewLine
  # Tag
  $str = GenerateTagList
  $sFileContent += '* meta  : ' + $str + [environment]::NewLine

  $sFileContent += `
'***************************************************************************************************/'`
    + [environment]::NewLine

  # code template
  $sFileContent += GenerateClassTemplate

  $outputFilePath = GenerateOutputFileName
  # Change encoding if we have interesting characters such as copyright, or greek or latin symbols
  Set-Content -LiteralPath $outputFilePath -Value $sFileContent -Encoding ASCII
  Start-Process devenv /Edit, $outputFilePath
}

function Main() {
  switch ( $Command ) {
    'GenerateTemplate' {
      GenerateTemplateCode
    }
    'open' {
      if ((Get-Location).Path.EndsWith('Problem-Solving')) {
        $Path = $OutDirPath + '\' + $Path
      }
      if (! (Test-Path $Path)) {
        'Invalid source file path provided!'
        return
      }
      Start-Process devenv /Edit, $Path
    }
    'tempLintCmd' {
      # temporary abusing `OutDirPath`
      # Handling error cases
      $defaultStr = 'D:\Code\Problem-Solving'
      if ($Path -eq $defaultStr) {
        'Path must be provided!'
        return
      }
      if (! (Get-Location).Path.EndsWith('Problem-Solving')) {
        'Invalid current dir!'
        return
      }
      $lintPath = 'general-solving\lintcode\' + $Path
      if (! (Test-Path $lintPath)) {
        'Invalid source file path provided!'
        return
      }
      $gitLintPath = 'general-solving\lintcode\' + $Path.TrimStart('0')
      git log -- $gitLintPath
      Start-Process devenv /Edit, $lintPath
    }
    default {
      'Unknown command line argument: ' + $Command + ' provided!'
    }
  }
}

# Entry Point
Main
