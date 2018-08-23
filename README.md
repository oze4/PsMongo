# PsMongo

<h1>[Original Repository Can Be Found Here (not in Visual Studio .sln Format)](https://github.com/oze4/PsMongo_Original)</h1>

Powershell module to interact with MongoDB. [More detailed, "live" examples can be found here.](https://github.com/oze4/PsMongo/blob/master/How-To/psMongo_ReadMe.ps1). These examples also contain test JSON data you can use to test saving and retrieving MongoDB data.

<h3>PsMongo Advantages</h3>

* Can interact with multiple MongoDB Databases or MongoDB Instances, from one Powershell session

* Grab Mongo Documents from a Collection straight into a PSCustomObject

* Supports local MongoDB Authentication

* Uses supported C# MongoDB Driver


<h3>Module Functions</h3>

* Import-PsMongoDLL
    * Must be used as the first command after the module is imported. Use parameter ```-PsMongoDllLocation``` to point to the location that you saved PsMongo.dll to

* New-MongoConnection
    * Must be ran "second" in order to interact with MongoDB.

* New-MongoDatabase
    * Create a new MongoDB after binding to a MongoDB Server.

* New-MongoCollection
    * Create a new Mongo Collection after binding to a MongoDB Server & Database.

* Add-JsonDocumentIntoMongoCollection
    * Allows you to save JSON files or JSON objects/data to a Mongo Collection.

* Get-AllDocumentsFromMongoCollection
    * Returns every document from the specified Mongo Collection (once you are bound to both a MongoDB Server and Database).

* Bind-ToMongoDatabase
    * Use if you want to change the DB you are currently connected to, or if you originally only binded to a MongoDB Server vs Server and Database

* ConvertFrom-BsonToJson
  * Allows you to convert a MongoDB BsonDocument to a JSON object.

* Remove-JsonDocumentFromMongoCollection
    * Essentially, grab a document from a Collection, then send it back with this command to delete it (is what happens under the hood).

* Remove-MongoCollection
    * Allows you to drop or delete a Mongo Collection once you are bound to a MongoDB.

* Remove-MongoDatabase
    * Allows you to drop or delete a MongoDB.

* Confirm-Selection
    * should really be private

