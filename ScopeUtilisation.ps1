<#
.SYNOPSIS
    This script tells you the utilisation of your DHCP scope.
 
.DESCRIPTION
    This script tells you the utilisation of your DHCP scope.
 
.INPUTS
    Netsh output
 
.OUTPUTS
    The scope utilisation as decimal.
 
 
.EXAMPLE
    $DhcpServer = 'server.com.au'
    $Scope = '11.22.52.0'
 
    GetScopeUtilisation $DhcpServer $Scope
 
.NOTES
    Author: dklempfner@gmail.com
    Date: 08/05/2017
#>

function ExtractTextBetweenEqualsAndDot
{
    Param([Parameter(Mandatory=$true)][String]$Line)
   
    $startIndex = $Line.IndexOf('=') + 1  
    $lastIndexOfDot = $Line.LastIndexOf('.')
    $length = $lastIndexOfDot - $startIndex
    if($length -lt 0)
    {
        Write-Error "Could not extract number from $Line"
    }
    $text = $Line.Substring($startIndex, $length).Trim()
    return $text
}
 
function GetScopeUtilisation
{
    param([Parameter(Mandatory=$true)][String]$DhcpServer,
          [Parameter(Mandatory=$true)][String]$Scope)   
 
    $netshOutput = netsh dhcp server "\\$DhcpServer" show mibinfo

    <#
    The following is an example of what the above netsh command can give you:

                MIBCounts:
                Discovers = 1566395.
                Offers = 711864.
                Requests = 1142907.
                Acks = 1846248.
                Naks = 5.
                Declines = 1.
                Releases = 29.
                ServerStartTime = Saturday, 22 April 2017 01:37:20  
                Scopes = 3.
                Subnet = 11.11.66.0.
                                No. of Addresses in use = 20.
                                No. of free Addresses = 142.
                                No. of pending offers = 1.
                Subnet = 11.11.68.128.
                                No. of Addresses in use = 4.
                                No. of free Addresses = 65.
                                No. of pending offers = 0.
                Subnet = 11.11.69.0.
                                No. of Addresses in use = 17.
                                No. of free Addresses = 183.
                                No. of pending offers = 0.
    #>
 
    for($i = 0; $i -lt $netshOutput.Count; $i++)
    {                   
        if($netshOutput[$i] -and $netshOutput[$i].Contains("Subnet = $scope"))
        {       
            $indexOfNumberOfAddressesInUse = $i + 1
            $numberOfAddressesInUse = ExtractTextBetweenEqualsAndDot $netshOutput[$indexOfNumberOfAddressesInUse]
               
            $indexOfNumberOfFreeAddresses = $i + 2
            $numberOfFreeAddresses = ExtractTextBetweenEqualsAndDot $netshOutput[$indexOfNumberOfFreeAddresses]
               
            $indexOfNumberOfPendingOffers = $i + 3
            $numberOfPendingOffers = ExtractTextBetweenEqualsAndDot $netshOutput[$indexOfNumberOfPendingOffers]
               
            $totalNumberOfAddresses = [int]$numberOfAddressesInUse + [int]$numberOfFreeAddresses + [int]$numberOfPendingOffers
 
            $scopeUtilisation = [double]$numberOfAddressesInUse/[double]$totalNumberOfAddresses
            $scopeUtilisationRoundedTo2DecimalPlaces = [System.Math]::Round($scopeUtilisation, 2)
            return $scopeUtilisationRoundedTo2DecimalPlaces
        }
    }
}