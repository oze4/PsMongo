using System;
using System.Linq;
using MongoDB.Driver;
using MongoDB.Bson;
using MongoDB.Bson.IO;
using System.Collections.Generic;

namespace PsMongo
{
    public class PsMongoContext
    {
        public string MongoServer { get; set; }
        public string MongoDatabaseName { get; set; }
        public bool MongoIsConnected { get; set; }
        private string MongoUsername { get; set; }
        private string MongoPassword { get; set; }
        private IMongoClient IMongoClient { get; set; }
        private IMongoDatabase IMongoDatabase { get; set; }

        public PsMongoContext(string mongoServer)
        {
            this.MongoServer = mongoServer;
            this.BindToMongo(mongoServer);
        }
        public PsMongoContext(string mongoServer, string databaseName)
        {
            this.MongoServer = mongoServer;
            this.MongoDatabaseName = databaseName;
            this.BindToMongo(mongoServer, databaseName);
        }
        public PsMongoContext(string mongoServer, string localmongousername, string localmongopassword)
        {
            this.MongoServer = mongoServer;
            this.MongoUsername = localmongousername;
            this.MongoPassword = localmongopassword;
            this.BindToMongo(mongoServer, localmongousername, localmongopassword);
        }
        public PsMongoContext(string mongoServer, string databaseName, string localmongousername, string localmongopassword)
        {
            this.MongoServer = mongoServer;
            this.MongoDatabaseName = databaseName;
            this.MongoUsername = localmongousername;
            this.MongoPassword = localmongopassword;
            this.BindToMongo(mongoServer, databaseName, localmongousername, localmongopassword);
        }
        private PsMongoContext BindToMongo(string server)
        {
            try
            {
                var connectionString = string.Format("mongodb://{0}:27017", server);
                this.IMongoClient = new MongoClient(connectionString);
                var dbs = IMongoClient.ListDatabases().ToList();
                if (dbs != null)
                {
                    this.MongoIsConnected = true;
                    return this;
                }
                else
                {
                    this.MongoIsConnected = false;
                    return null;
                }
            }
            catch (Exception e)
            {
                this.MongoIsConnected = false;
                throw new Exception("Something went wrong Binding to Mongo! Full Error:\r\n\r\n" + e.Message);
            }
        }
        private PsMongoContext BindToMongo(string server, string databasename)
        {
            try
            {
                var connectionString = string.Format("mongodb://{0}:27017/{1}", server, databasename);
                this.IMongoClient = new MongoClient(connectionString);
                var dbs = IMongoClient.ListDatabases().ToList();
                if (dbs != null)
                {
                    this.MongoIsConnected = true;
                    this.IMongoDatabase = this.IMongoClient.GetDatabase(databasename);
                    return this;
                }
                else
                {
                    this.MongoIsConnected = false;
                    throw new Exception("Unable to query for databases on server '" + server + "'!");
                }
            }
            catch (Exception e)
            {
                this.MongoIsConnected = false;
                throw new Exception("Something went wrong Binding to Mongo! Full Error:\r\n\r\n" + e.Message);
            }
        }
        private PsMongoContext BindToMongo(string server, string localmongousername, string localmongopassword)
        {
            try
            {
                var connectionString = string.Format("mongodb://{0}:{1}@{2}:27017", localmongousername, localmongopassword, server);
                this.IMongoClient = new MongoClient(connectionString);
                this.MongoIsConnected = true;
                return this;
            }
            catch (Exception e)
            {
                this.MongoIsConnected = false;
                throw new Exception("Something went wrong Binding to Mongo! Full Error:\r\n\r\n" + e.Message);
            }
        }
        private PsMongoContext BindToMongo(string server, string databasename, string localmongousername, string localmongopassword)
        {
            try
            {
                var connectionString = string.Format("mongodb://{0}:{1}@{2}:27017/{3}", localmongousername, localmongopassword, server, databasename);
                this.IMongoClient = new MongoClient(connectionString);
                this.IMongoDatabase = this.IMongoClient.GetDatabase(databasename);
                this.MongoIsConnected = true;
                return this;
            }
            catch (Exception e)
            {
                this.MongoIsConnected = false;
                throw new Exception("Something went wrong Binding to Mongo! Full Error:\r\n\r\n" + e.Message);
            }
        }
        private bool BindToMongoDatabase(string dbname)
        {
            if (this.MongoServer == null)
            {
                throw new Exception("In order to connect to a database you must first connect to a server.");
            }
            else
            {
                this.BindToMongo(this.MongoServer, dbname);
                this.IMongoDatabase = this.IMongoClient.GetDatabase(dbname);
                this.MongoDatabaseName = dbname;
                return true;
            }
        }
        public bool ConnectToMongoDatabase(string databasename)
        {
            return this.BindToMongoDatabase(databasename);
        }

        public bool CreateNewDatabase(string databaseName, string collectionName) // each database must be created with a collection or else empty databases remove themselves
        {
            try
            {
                // even tho this says get database, if the database doesnt exist - it cretes it
                var newDB = this.IMongoClient.GetDatabase(databaseName);
                newDB.CreateCollection(collectionName);
                return true;
            }
            catch (Exception e)
            {
                throw new Exception("Something went wrong creating database. Full Error\r\n\r\n" + e.Message);
            }
        }
        public bool RemoveDatabase(string databaseName)
        {
            try
            {
                this.IMongoClient.DropDatabase(databaseName);
                return true;
            }
            catch (Exception e)
            {
                throw new Exception("Something went wrong while removing database '" + databaseName + "'.\r\nFull Error\r\n\r\n" + e.Message);
            }
        }
        public bool CreateNewCollection(string collectionName)
        {
            try
            {
                this.IMongoDatabase.CreateCollection(collectionName);
                return true;
            }
            catch (Exception e)
            {
                throw new Exception("Something went wrong creating database. Full Error\r\n\r\n" + e.Message);
            }
        }
        public bool RemoveCollection(string collectionName)
        {
            try
            {
                this.IMongoDatabase.DropCollection(collectionName);
                return true;
            }
            catch (Exception e)
            {
                throw new Exception("Something went wrong while removing collection '" + collectionName + "'.\r\nFull Error\r\n\r\n" + e.Message);
            }
        }
        public List<BsonDocument> GetAllDocumentsFromCollection(string collectionName)
        {
            try
            {
                var collection = this.IMongoDatabase.GetCollection<BsonDocument>(collectionName);
                return collection.Find(Builders<BsonDocument>.Filter.Empty).ToList();
            }
            catch (Exception e)
            {
                throw new Exception("Something went wrong while gather documents from collection: '" + collectionName + "'!\r\nFull Error:\r\n\r\n" + e.Message);
            }
        }
        public IMongoCollection<BsonDocument> GetMongoCollection(string collectionName)
        {
            try
            {
                return this.IMongoDatabase.GetCollection<BsonDocument>(collectionName);
            }
            catch (Exception e)
            {
                throw new Exception("Something went wrong while locating collection: '" + collectionName + "'!\r\nFull Error:\r\n\r\n" + e.Message);
            }
        }
        public bool InsertDocumentIntoMongoCollection(string json, string collectionName)
        {
            try
            {
                var collection = this.IMongoDatabase.GetCollection<BsonDocument>(collectionName);
                var bson_ = json.ToBsonDocument();
                collection.InsertOne(bson_);
                return true;
            }
            catch (Exception e)
            {
                throw new Exception("Something went wrong while inserting document into collection!\r\n\r\nFull Error:\r\n\r\n" + e.Message);
            }
        }
        public bool RemoveDocumentFromMongoCollection(string jsonDocument, string collectionName)
        {
            try
            {
                var collection = this.IMongoDatabase.GetCollection<BsonDocument>(collectionName);
                var doc = MongoConverter.JSONtoBSON(jsonDocument);
                if (doc == null)
                {
                    return false;
                }
                else
                {
                    collection.DeleteOne(doc);
                    return true;
                }
            }
            catch (Exception e)
            {
                var m = string.Format("Something went wrong while removing document from collection! Full Error:\r\n\r\n{0}", e.Message);
                throw new Exception(m);
            }
        }
    }
    public class MongoConverter
    {
        public static string BSONtoJSON(BsonDocument bson)
        {
            // JsonOutputMode.Strict is what lets us pull from MongoDB straight into PSCustomObject
            return bson.ToJson(new JsonWriterSettings { OutputMode = JsonOutputMode.Strict });
        }
        public static BsonDocument JSONtoBSON(string json)
        {
            return MongoDB.Bson.Serialization.BsonSerializer.Deserialize<BsonDocument>(json);
        }
    }
}