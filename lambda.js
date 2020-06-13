// 'Image store' nodejs6.10 runtime AWS Lambda function

// load sdk
const AWS = require('aws-sdk');
// set region
AWS.config.update({ region: 'eu-west-1' });

// create s3 bucket service object
const s3 = new AWS.S3({ apiVersion: '2012-08-10' });

// create DynamoDB service object
const ddb = new AWS.DynamoDB.DocumentClient();

const ddbTable = process.env.DDBtable;

let id = 0;

exports.handler = async(event, context, callback) => {
    console.log('\nevent: ', JSON.stringify(event, null, 2));

    // console.log('\nusing ddb table: ', ddbTable);

    // console.log('\ncontext: ', context);

    const srcKey = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, " "));
    // console.log('srcKey: ', srcKey);

    const srcBucket = event.Records[0].s3.bucket.name;
    // console.log('\nsrcBucket: ', srcBucket);

    const srcSize = event.Records[0].s3.object.size

    //   s3.listBuckets((err, data) => {
    //     if (err) console.log('error: ', err);
    //     else console.log('buckets: ', data);
    //   });
    // guide : https://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/dynamodb-example-table-read-write.html

    // const uploadID = ++id

    const params = {
      TableName: 'bucket_image_registry',
      Item: {
        ImageTitle: srcKey,
        ImageID: (id += 1).toString(),
        Score: 0,
        srcBucket: srcBucket,
        srcSize: srcSize
        }
      }

    console.log('uploading...')
    //   // Call DynamoDB to add the item to the table
    return ddb.put(params)
      .promise()
      .then(res => {
        console.log(res)
        callback('wahoo!')
      }).catch(err => {
        console.log(err)
        callback('boo!')
      })

};
