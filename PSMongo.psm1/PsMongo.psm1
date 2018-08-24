#
#                        __  __                                 
#                       |  \/  |                                
#          _ __    ___  | \  / |   ___    _ __     __ _    ___  
#         | '_ \  / __| | |\/| |  / _ \  | '_ \   / _` |  / _ \ 
#         | |_) | \__ \ | |  | | | (_) | | | | | | (_| | | (_) |
#         | .__/  |___/ |_|  |_|  \___/  |_| |_|  \__, |  \___/ 
#         | |                                      __/ |        
#         |_|                                     |___/         
#
#
#
#
#a Powershell module by Matt Oestreich

<#

        *                                                  *
        ~ This module is designed to interact with MongoDB ~
        *                                                  *

        LICENSE INFO:
        Copyright $(Get-Date) (c) M@. 

        All rights reserved.

        MIT License

        Permission is hereby granted", "free of charge", "to any person obtaining a copy
        of this software and associated documentation files (the ""Software"")", "to deal
        in the Software without restriction", "including without limitation the rights
        to use", "copy", "modify", "merge", "publish", "distribute", "sublicense", "and/or sell 
        copies of the Software", "and to permit persons to whom the Software is
        furnished to do so", "subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED *AS IS*", "WITHOUT WARRANTY OF ANY KIND", "EXPRESS OR
        IMPLIED", "INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM", "DAMAGES OR OTHER
        LIABILITY", "WHETHER IN AN ACTION OF CONTRACT", "TORT OR OTHERWISE", "ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.

        IMPORTANT NOTICE:  THE SOFTWARE ALSO CONTAINS THIRD PARTY AND OTHER
        PROPRIETARY SOFTWARE THAT ARE GOVERNED BY SEPARATE LICENSE TERMS. BY ACCEPTING
        THE LICENSE TERMS ABOVE", "YOU ALSO ACCEPT THE LICENSE TERMS GOVERNING THE
        THIRD PARTY AND OTHER SOFTWARE", "WHICH ARE SET FORTH IN ThirdPartyNotices.txt

#>




$Global:MONGO_SESSION_INFO = @{
    "ImportedDlls" = "null"
}
 
function Import-PsMongoDLL
{
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({ (([System.IO.File]::Exists($_)) -and ($_.EndsWith("PsMongo.dll")))
                    
                    "FILE EITHER DOES NOT EXIST, OR IS NOT 'PsMongo.dll'"
        
        })]
        [string]$PsMongoDllLocation             
    )
    
    try { 
       Import-Module $PsMongoDllLocation  
       $Global:MONGO_SESSION_INFO.ImportedDlls = $true
    } catch {    
        $Global:MONGO_SESSION_INFO.ImportedDlls = $false
        Write-Host "`r`n               Unable to import PsMongo.dll!                `r`n`r`nFull Error:`r`n`r`n$($_)`r`n`r`n" -f Red -b Black        
    }
    
}

function New-MongoConnection
{
    # If database name is empty, mongo will connect to the admin db by default
    [cmdletbinding(DefaultParameterSetName="DFLT")]
    param(
        [Parameter(Mandatory=$true)]
        [string]$MongoServerHostname,
        
        [Parameter(Mandatory=$false)]
        [string]$MongoDatabaseName,
        
        [Parameter(Mandatory=$false, ParameterSetName="UNPW")]    
        [string]$MongoUsername,
        
        [Parameter(Mandatory=$true, ParameterSetName="UNPW")]    
        [string]$MongoPassword
    )
    
    if($Global:MONGO_SESSION_INFO.ImportedDlls){
        if((-not $PSBoundParameters["MongoDatabaseName"]) -and (-not $PSBoundParameters["MongoUsername"]) -and (-not $PSBoundParameters["MongoPassword"])){
            [PsMongo.PsMongoContext]::new($MongoServerHostname)
        }
        if($PSBoundParameters["MongoDatabaseName"]){
            [PsMongo.PsMongoContext]::new($MongoServerHostname, $MongoDatabaseName)  
        }
        if(-not ($PSBoundParameters["MongoDatabaseName"]) -and ($PSBoundParameters["MongoUsername"]) -and ($PSBoundParameters["MongoPassword"])){
            [PsMongo.PsMongoContext]::new($MongoServerHostname, $MongoUsername, $MongoPassword)
        }
        if(($PSBoundParameters["MongoDatabaseName"]) -and ($PSBoundParameters["MongoUsername"]) -and ($PSBoundParameters["MongoPassword"])){
            [PsMongo.PsMongoContext]::new($MongoServerHostname, $MongoDatabaseName, $MongoUsername, $MongoPassword)
        }                  
    } else {
        Write-Host "Unable to connect to Mongo Server '$MongoServerHostname' on database '$MongoDatabaseName' because the required libraries are not loaded!" -f Red
    }

}

function Get-AllDocumentsFromMongoCollection
{

    param(
        [Parameter(Mandatory=$true)]
        [PsMongo.PsMongoContext]$MongoConnection,
        
        [Parameter(Mandatory=$true)]
        [string]$CollectionName
    )
    
    if($Global:MONGO_SESSION_INFO.ImportedDlls){
        try {
            $AllJsonDocuments = @()
            $AllBsonDocuments = $MongoConnection.GetAllDocumentsFromCollection($CollectionName)
            if($AllBsonDocuments.Count -gt 0){
                foreach($bd in $AllBsonDocuments){
                    $AllJsonDocuments += ConvertFrom-BsonToJson -BsonDocument $bd
                }
                # return all documents as json
                $AllJsonDocuments
            } else {
                Write-Host "No documents found in collection '$($CollectionName.ToUpper())'" -f Yellow
            }
        } catch {
            Write-Host "[Connected Mongo Database may be null, are you connected to a database?]::Unable to get documents from collection '$CollectionName'!" -f Red
        }
    } else {
        Write-Host "Unable to get documents from collection '$CollectionName' because the required libraries are not loaded!" -f Red
    }

}

function ConvertFrom-BsonToJson
{
    
    param(
        [Parameter(Mandatory=$true)]
        [MongoDB.Bson.BsonDocument]$BsonDocument              
    )
    
    if($Global:MONGO_SESSION_INFO.ImportedDlls){
        [PsMongo.MongoConverter]::BSONtoJSON($BsonDocument) | ConvertFrom-Json    
    } else {
        Write-Host "Unable to convert Bson Document to JSON, because the required libraries are not loaded!" -f Red
    }            
}

function Add-JsonDocumentIntoMongoCollection
{

    param(
        [Parameter(Mandatory=$true)]
        [PsMongo.PsMongoContext]$MongoConnection,
        
        [Parameter(Mandatory=$true)]
        [string]$CollectionName,
    
        [Parameter(Mandatory=$true)]
        [string]$JsonData
    )
    
    if($Global:MONGO_SESSION_INFO.ImportedDlls){     
        try {     
            $stringToJson = $null
            $stringToJson = $JsonData | ConvertFrom-Json -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        } catch { 
            Write-Host "[Add-JsonDocumentIntoMongoCollection:param:JsonData::_value_]Not valid JSON data" -f Red 
        } 
        try { 
            $BsonData   = [PsMongo.MongoConverter]::JSONtoBSON($JsonData)
            $Collection = $MongoConnection.GetMongoCollection($CollectionName)
            $Collection.InsertOne($BsonData)
        } catch {
            Write-Host "Something went wrong saving document to database '$($MongoConnection.MongoDatabaseName)' in collection ''! Full Error: $($_)" -f Red
        }        
    } else {
        Write-Host "Either unable to import JSON data from '$JsonData' or save data to Mongo Collection '$CollectionName', because the required libraries are not loaded!" -f Red
    }
}   

function Remove-JsonDocumentFromMongoCollection
{

    param(
        [Parameter(Mandatory=$true)]
        [PsMongo.PsMongoContext]$MongoConnection,
        
        [Parameter(Mandatory=$true)]
        [string]$CollectionName,
    
        [Parameter(Mandatory=$true)]
        [string]$JsonDocument
    )
    
    if($Global:MONGO_SESSION_INFO.ImportedDlls){
    
        $MongoConnection.RemoveDocumentFromMongoCollection($JsonDocument, $CollectionName)
    } else {
        Write-Host "Unable to remove JSON Document from MongoDB because the required libraries are not loaded!" -f Red
    }

}

function New-MongoDatabase
{

    param(
        [Parameter(Mandatory=$true)]
        [PsMongo.PsMongoContext]$MongoConnection,
        
        [Parameter(Mandatory=$true)]
        [string]$NewDatabaseName,
        
        [Parameter(Mandatory=$true)]
        [string]$NewCollectionName # empty databases arent allowed in Mongo so we have to either insert a collection, or insert data
    )

    if($Global:MONGO_SESSION_INFO.ImportedDlls){
        $MongoConnection.CreateNewDatabase($NewDatabaseName, $NewCollectionName)
    } else {
        Write-Host "Unable to create new database because the required libraries are not loaded!" -f Red
    }

}

function Bind-ToMongoDatabase
{

    param(
        [Parameter(Mandatory=$true)]
        [PsMongo.PsMongoContext]$MongoConnection,
        
        [Parameter(Mandatory=$true)]
        [string]$DatabaseName
    )
    
    if($Global:MONGO_SESSION_INFO.ImportedDlls){
        $MongoConnection.ConnectToMongoDatabase($DatabaseName)
    } else {
        Write-Host "Unable to connect to database because the required libraries are not loaded!" -f Red
    }    
    
}

function Remove-MongoDatabase
{

    param(
        [Parameter(Mandatory=$true)]
        [PsMongo.PsMongoContext]$MongoConnection,
        
        [Parameter(Mandatory=$true)]
        [string]$DatabaseName,
        
        [Parameter(Mandatory=$false)]
        [switch]$ForceDatabaseDrop
    )
    
    if($Global:MONGO_SESSION_INFO.ImportedDlls){
        if(-not ($PSBoundParameters["ForceDatabaseDrop"])){
            $ShouldContinue = Confirm-Selection -Confirm DatabaseDrop
            if($ShouldContinue){
                $MongoConnection.RemoveDatabase($DatabaseName)
            }
        } else {
            $MongoConnection.RemoveDatabase($DatabaseName)
        }
    } else {
        Write-Host "Unable to remove database because the required libraries are not loaded!" -f Red
    }

}

function New-MongoCollection
{

    param(
        [Parameter(Mandatory=$true)]
        [PsMongo.PsMongoContext]$MongoConnection,
        
        [Parameter(Mandatory=$true)]
        [string]$NewCollectionName    
    )
    
    if($Global:MONGO_SESSION_INFO.ImportedDlls){
        if($MongoConnection.MongoDatabaseName -eq $null){
            Write-Host "You are not currently connected to any databases! Please connect to a database in order to create a collection!" -f Red
        } else {
            # create new collection in database we are currently connected to
            $MongoConnection.CreateNewCollection($NewCollectionName)
        }
    } else {
        Write-Host "Unable to create new collection because the required libraries are not loaded!" -f Red
    }
    
}

function Remove-MongoCollection
{

    param(
        [Parameter(Mandatory=$true)]
        [PsMongo.PsMongoContext]$MongoConnection,
        
        [Parameter(Mandatory=$true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory=$false)]
        [switch]$ForceCollectionDrop
    )
    
    if($Global:MONGO_SESSION_INFO.ImportedDlls){
        if($MongoConnection.MongoDatabaseName -eq $null){
            Write-Host "You are not currently connected to any databases! Please connect to a database in order to create a collection!" -f Red
        } else {
            if(-not ($PSBoundParameters["ForceCollectionDrop"])){
                $ShouldContinue = Confirm-Selection -Confirm CollectionDrop
                if($ShouldContinue){
                    $MongoConnection.RemoveCollection($CollectionName)
                }
            } else {
                $MongoConnection.RemoveCollection($CollectionName)
            }
        }
    } else {
        Write-Host "Unable to remove collection because the required libraries are not loaded!" -f Red
    }

}

function Confirm-Selection
{

    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet("DatabaseDrop", "CollectionDrop")]
        [string]$Confirm
    )

    switch($Confirm){
        "DatabaseDrop" {  
            Write-Host "`r`n`r`nIf the 'ForceDatabaseDrop' switch is not used you have to confirm that you would like to drop a database...`r`n" -f Yellow
        }
        "CollectionDrop" {  
            Write-Host "`r`n`r`nIf the 'ForceCollectionDrop' switch is not used you have to confirm that you would like to drop a collection...`r`n" -f Yellow
        }
    }    
    Write-Host "Would you like to continue?`r`n    1. Yes`r`n    2. No" -f Red    
    [string]$Answer = Read-Host "(1=Continue|2=Cancel)"
    if(($Answer -ne "1") -and ($Answer -ne "2")){
        Write-Host "Please make a valid selection!" -f Red
        Pause
        Confirm-Selection
    } else {
        switch($Answer){
            "1" { return $true }
            "2" { return $false }
        }
    }
}





# has to be the last thing in module
try {
    Export-ModuleMember *
} catch {
    # do nothing, only here to suppress ISE errors
}
