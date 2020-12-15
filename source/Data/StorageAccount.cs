using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using Azure.Storage.Blobs;
using Newtonsoft.Json;

namespace SantaWishList
{
    
    public class StorageAccount
    {
            string connectionString = Environment.GetEnvironmentVariable("connectionString");
            string storageContainerName = Environment.GetEnvironmentVariable("storageContainerName").ToLower();
            private BlobContainerClient GetClient()
            {

            var blobServiceClient = new BlobServiceClient(connectionString);
            var blobContainerClient = blobServiceClient.GetBlobContainerClient(storageContainerName);
            blobContainerClient.CreateIfNotExists();

            return blobContainerClient;
            
            }
            public async Task UploadWishList(List<PresentsModel> wishlist, string FamilyName)
            {

            BlobContainerClient blobContainerClient = GetClient();
            string name = Regex.Replace( FamilyName, @"s", "" );
            var blobName = name + Guid.NewGuid().ToString() + ".txt";

            var json = JsonConvert.SerializeObject(wishlist);

                using (MemoryStream ms = new MemoryStream(Encoding.UTF8.GetBytes(json)))
                {
                    await blobContainerClient.UploadBlobAsync(blobName, ms);
                }
            }
            
    }
}