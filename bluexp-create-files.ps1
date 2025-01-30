# Function to capture the third octet of the IP address
function Get-ThirdOctet {
    # Get the IP address of the host (local machine in this case)
    $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.PrefixLength -eq 24 }).IPAddress

    # Check if the IP address is found
    if ($ipAddress) {
        # Split the IP address into its components (octets)
        $ipParts = $ipAddress -split '\.'

        # Ensure we have enough parts (4 octets)
        if ($ipParts.Length -eq 4) {
            # Return the third octet
            return $ipParts[2]
        } else {
            Write-Host "Invalid IP address format" -ForegroundColor Red
            return $null
        }
    } else {
        Write-Host "No IPv4 address found" -ForegroundColor Red
        return $null
    }
}

# Capture the third octet of the IP address
$thirdOctet = Get-ThirdOctet

# Check if the third octet was successfully retrieved
if ($null -eq $thirdOctet) {
    Write-Host "Failed to retrieve third octet. Exiting." -ForegroundColor Red
    exit
}

# Modify the SMB share path dynamically with the third octet
$smbSharePath = "\\10.242.${thirdOctet}.62\share"  # Modify the path with the third octet

# Define the number of files to create
$fileCount = 100

# Define the size of random data to generate in each file (in bytes)
$fileSize = 1024  # 1 KB file size (you can adjust this)

# Define the path and filename for sensitive data
$filePath = $smbSharePath

# Check if the SMB share path exists
if (-Not (Test-Path -Path $smbSharePath)) {
    Write-Host "Error: SMB share path '$smbSharePath' does not exist." -ForegroundColor Red
    exit
}

# Function to generate random data
function Generate-RandomData {
    param (
        [int]$size
    )

    $randomData = -join ((65..90) + (97..122) | Get-Random -Count $size | ForEach-Object {[char]$_})
    return $randomData
}

# Loop to create files
for ($i = 1; $i -le $fileCount; $i++) {
    # Generate random data
    $randomContent = Generate-RandomData -size $fileSize

    # Create the file path
    $filePath = Join-Path -Path $smbSharePath -ChildPath ("file_" + "{0:D4}" -f $i + ".txt")

    # Write random data to the file
    Set-Content -Path $filePath -Value $randomContent -Force

    Write-Host "Created: $filePath"
}

# Define the source file and destination folder for duplicate files
#$sourceFile = "C:\path\to\original\file.txt"
$sourceFile = "Z:\pii.txt"
# $destinationFolder = "C:\path\to\destination\folder"
$destinationFolder = $smbSharePath

# Create a loop to create multiple duplicates
for ($i = 1; $i -le 10; $i++) {
    # Construct the new file name with a number appended
    $newFileName = "file_copy_$i.txt"

    # Copy the file to the destination folder with the new name
    Copy-Item -Path $sourceFile -Destination "$destinationFolder\$newFileName"
}

# Generate sensitive data
$data = "Name,Age,Email,SS#`n" +
        "John,25,john@blah.com,000-38-5663`n" +
        "Jane,30,jane@blah.com,004-38-566`n" +
        "Peter,35,peter@blah.com,007-38-566"

# Write sensitive data to the file
Set-Content -Path $filePath -Value $data

Write-Host "Successfully created $fileCount files with random data on SMB share." -ForegroundColor Green
Write-Host "Successfully created 10 duplicate files on SMB share." -ForegroundColor Green
Write-Host "Successfully created 10 sensitive data files on SMB share." -ForegroundColor Green