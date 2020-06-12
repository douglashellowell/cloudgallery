// 'Image store' nodejs6.10 runtime AWS Lambda function

// load sdk
const AWS = require('aws-sdk');
// set region
AWS.config.update({ region: 'eu-west-1' });

// create s3 bucket service object
const s3 = new AWS.S3({ apiVersion: '2012-08-10' });

// create DynamoDB service object
const ddb = new AWS.DynamoDB({ apiVersion: '2012-08-10' });

const ddbTable = process.env.DDBtable;

exports.handler = async (event, context, callback) => {
  try {
    console.log('\nevent: ', JSON.stringify(event, null, 2));
  } catch {
    console.log('\nevent: ', event);
  }
  console.log('\nusing ddb table: ', ddbTable);

  console.log('\ncontext: ', context);

  const srcKey = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, " "));
  console.log('srcKey: ', srcKey);
  
  const srcBucket = event.Records[0].s3.bucket.name;
  console.log('\nsrcBucket: ', srcBucket);

  //   s3.listBuckets((err, data) => {
  //     if (err) console.log('error: ', err);
  //     else console.log('buckets: ', data);
  //   });
  // guide : https://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/dynamodb-example-table-read-write.html

  // var params = {
  //     TableName: 'CUSTOMER_LIST',
  //     Item: {
  //       'CUSTOMER_ID' : {N: '001'},
  //       'CUSTOMER_NAME' : {S: 'Richard Roe'}
  //     }
  //   };

  //   // Call DynamoDB to add the item to the table
  //   ddb.putItem(params, function(err, data) {
  //     if (err) {
  //       console.log("Error", err);
  //     } else {
  //       console.log("Success", data);
  //     }
  //   });

  callback(null, 'wahoo!');
};
