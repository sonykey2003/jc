# AWS Serverless (Lambda) functions - JumpCloud Workloads

### Getting Started
* This library will focus on Python scripts.
* Runtime recommendation - Python 3.9.6 minimum


### How to Deploy A Function

* Create a function on the console
<img width="600" alt="image" src="https://user-images.githubusercontent.com/19852184/206387537-e7ea1b2e-0202-41cb-b875-a3b1baf5a61d.png">

* Or use the [AWS cli](https://docs.aws.amazon.com/cli/latest/reference/lambda/create-function.html) like [this](https://medium.com/@corymaklin/tutorial-amazon-web-services-part-3-lambda-functions-with-aws-cli-ba9f53c5f5ec).

* Create the [Lambda Layers](https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html?icmpid=docs_lambda_help) for your Python packages - i.e. requests, jcapiv1, jcapiv2. 
    * Make sure the file sturcture in zip looks like this:
    ```shell
    pillow.zip
    │ python/PIL
    └ python/Pillow-5.3.0.dist-info
    ```
* Add the layers to the function:
![image](https://user-images.githubusercontent.com/19852184/206390195-c6a79fb5-b5b4-4d97-8405-1399cf091dfb.png)
* Import the packages like you used to in the function code:
```py
import jcapiv1,jcapiv2,requests,json,datetime,os
```
**Thins are NOT working**

Due to the limitation on AWS Lambda Funtion - it has no shared memory device (/dev/shm), the lambda_multiprocessing library is NOT supported. Which is currently used by jcapiv1 & jcapiv2 SDKs.

Reference:
https://pypi.org/project/lambda-multiprocessing/
https://aws.amazon.com/blogs/compute/parallel-processing-in-python-with-aws-lambda/


## (WIP) Function 1 - addSystemGeoGroup

### What It Does

Adding JC Systems to Groups according to device's geo location, only moving the systems to designated by tracking back the days when it gets created. 

### Caveats

* Encouraged to run this script on a schedule - ideally at least once a day.
* This script is suitable (but not tailored) to run on any server / VM / device which tasked to run jobs (less favourable).
* Simply change the variable "backTrackDays" to any number of days suitable in your env.
* Set a large number of "backTrackDays" (like 10000) if you are running this for the first time, from your workstation ideally.
* Use a staggered approach by setting the "backTrackDays" if you have a large number of flee. - i.e. first do 10 days back, then 20 days back etc.
* Location info is fetched by "remoteIP" of the system and a query to http://ip-api.com/json/[IPAddress]
