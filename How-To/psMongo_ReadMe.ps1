<#================================================================================================================================================
        Import psMongo.psm1
 ================================================================================================================================================#>
 Import-Module "C:\mongo\psMongo.psm1"
#=================================================================================================================================================


<#================================================================================================================================================
        *HAVE TO IMPORT MONGO DLLs FIRST!!!*
 ================================================================================================================================================#>
Import-PsMongoDLL -PsMongoDllLocation "C:\mongo\PsMongo.dll"
#=================================================================================================================================================


<#================================================================================================================================================
        This is how you would connect to a MongoDB Server, this returns a PsMongoContext object, that you will need later
        Done so you can talk to many MongoDB instances from one Powershell session 
        If the MongoDatabaseName param isnt used, Mongo connects to the Admin db by default 
        Database and Collection names are case sensitive 
        Can either use no auth or local Mongo Auth as authentication sources
        Many different ways to bind to Mongo
================================================================================================================================================#>
# Bind to a server without auth
$MyMongoConnection_NoAuth_ServerBind     = New-MongoConnection -MongoServerHostname "mongo.domain.com"  
# Bind to a server and database with no auth
$MyMongoConnection_NoAuth_DatabaseBind   = New-MongoConnection -MongoServerHostname "mongo.domain.com" -MongoDatabaseName "MyNewDatabase" 
# Bind to a server with auth
$MyMongoConnection_WithAuth_ServerBind   = New-MongoConnection -MongoServerHostname "mongo.domain.com" -MongoUsername "test_user" -MongoPassword "Password1" 
# Bind to a server and database using auth
$MyMongoConnection_WithAuth_DatabaseBind = New-MongoConnection -MongoServerHostname "mongo.domain.com" -MongoDatabaseName "MyNewDatabase" -MongoUsername "test_user" -MongoPassword "Password1" 
# AFTER RUNNING New-MongoConnection - VIEW THE CONTENTS OF THE VARIABLE YOU TIE THE RETURN TO
#=================================================================================================================================================


<#================================================================================================================================================
        This example shows how you would create a database after binding to a server only
        Database and collection names are case sensitive 
        Must supply both a new DB name and a new Collection name, since MongoDB does not allow empty databases you either have to insert
        a new Collection or insert data to the DB
================================================================================================================================================#>
New-MongoDatabase -MongoConnection $MyMongoConnection_WithAuth_ServerBind -NewDatabaseName "MyNewDatabase" -NewCollectionName "MyNewCollection"
#=================================================================================================================================================


<#================================================================================================================================================
        This example shows how you would create a new collection once connected to a database        
================================================================================================================================================#>
New-MongoCollection -MongoConnection $MyMongoConnection_WithAuth_ServerBind -NewCollectionName "TheNewestCollectionCreated"
#=================================================================================================================================================



<#================================================================================================================================================
        This example shows how you would connect to the newly created database
================================================================================================================================================#>
Bind-ToMongoDatabase -MongoConnection $MyMongoConnection_WithAuth_ServerBind -DatabaseName "MyNewDatabase"
#=================================================================================================================================================



<#================================================================================================================================================
        This example shows how to insert JSON data to a collection that lives inside a database
================================================================================================================================================#>
# Since the JSON data you are trying to save may not be a string, I convert this string to an actual Powershell Object so this example is as accurate as possible
$SampleJsonDataString_1 = @"
{
    "fruit": "Apple",
    "size": "Large",
    "color": "Red"
}
"@
# Since the JSON data you are trying to save may not be a string, I convert this string to an actual Powershell Object so this example is as accurate as possible
$SampleJsonDataString_2 = @"
{
    "fruit": "Banana",
    "size": "Small",
    "color": "Yellow"
}
"@ 
$SampleJsonData_1 = $SampleJsonDataString_1 | ConvertFrom-Json 
$SampleJsonData_2 = $SampleJsonDataString_2 | ConvertFrom-Json
Add-JsonDocumentIntoMongoCollection -MongoConnection $MyMongoConnection_WithAuth_ServerBind -CollectionName "MyNewCollection" -JsonData ($SampleJsonData_1 | ConvertTo-Json) 
Add-JsonDocumentIntoMongoCollection -MongoConnection $MyMongoConnection_WithAuth_ServerBind -CollectionName "MyNewCollection" -JsonData ($SampleJsonData_2 | ConvertTo-Json) 
#=================================================================================================================================================


<#================================================================================================================================================
        This example shows how to gather all documents from a collection
        Gathers all documents, each document is converted to its own PSCustomObject for ease of use 
================================================================================================================================================#>
$MyMongoDocuments = Get-AllDocumentsFromMongoCollection -MongoConnection $MyMongoConnection_WithAuth_ServerBind -CollectionName "MyNewCollection"
$MyMongoDocuments # View the collected documents
#-----------------------------------------------------------------#
#-------------------return of $MyMongoDocuments-------------------#
#-----------------------------------------------------------------#
#                                                                 #
#        _id                              fruit  size  color      #
#        ---                              -----  ----  -----      #
#        @{$oid=5b6b3298b0356a74a8149b4f} Apple  Large Red        #
#        @{$oid=5b6b3298b0356a74a8149b50} Banana Small Yellow     #
#-----------------------------------------------------------------#
#=================================================================================================================================================


<#================================================================================================================================================
        This example shows how to remove a document from a collection
        First you need to grab the document you want to delete out of the database, and tie it to a variable
        We will use the last document we grabbed from the command above
================================================================================================================================================#>
$SingleDocument = $MyMongoDocuments | Where-Object { $_.fruit -eq "Apple" }
Remove-JsonDocumentFromMongoCollection -MongoConnection $MyMongoConnection_WithAuth_ServerBind -CollectionName "MyNewCollection" -JsonDocument ($SingleDocument | ConvertTo-Json)
#=================================================================================================================================================
