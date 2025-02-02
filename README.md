# puppygraph-on-k8s

Deploy PuppyGraph and iceberg on Kubernetes and simulate the Wiz security graph.

This is heavily based on
PuppyGraph's [cloud-security-graph-demo](https://github.com/puppygraph/puppygraph-getting-started/tree/main/use-case-demos/cloud-security-graph-demo)

## Prepare data ✅

We need to convert the data to parquet format. We will use Python + pandas library to read the CSV
file and write it to parquet format. Let's create a Python virtual environment and install the
required libraries.

```bash
python -m venv venv
source venv/bin/activate

pip install pandas pyarrow
```

Run the conversion script

```
python CsvToParquet.py ./csv_data ./parquet_data
CSV file ./csv_data/VPCs.csv has been successfully converted to Parquet. Output file: ./parquet_data/VPCs.parquet
CSV file ./csv_data/SecurityGroups.csv has been successfully converted to Parquet. Output file: ./parquet_data/SecurityGroups.parquet
CSV file ./csv_data/InternetGatewayVPC.csv has been successfully converted to Parquet. Output file: ./parquet_data/InternetGatewayVPC.parquet
CSV file ./csv_data/InternetGateways.csv has been successfully converted to Parquet. Output file: ./parquet_data/InternetGateways.parquet
CSV file ./csv_data/IngressRuleInternetGateway.csv has been successfully converted to Parquet. Output file: ./parquet_data/IngressRuleInternetGateway.parquet
CSV file ./csv_data/IngressRules.csv has been successfully converted to Parquet. Output file: ./parquet_data/IngressRules.parquet
CSV file ./csv_data/Users.csv has been successfully converted to Parquet. Output file: ./parquet_data/Users.parquet
CSV file ./csv_data/Resources.csv has been successfully converted to Parquet. Output file: ./parquet_data/Resources.parquet
CSV file ./csv_data/PublicIPs.csv has been successfully converted to Parquet. Output file: ./parquet_data/PublicIPs.parquet
CSV file ./csv_data/VMInstances.csv has been successfully converted to Parquet. Output file: ./parquet_data/VMInstances.parquet
CSV file ./csv_data/RoleResourceAccess.csv has been successfully converted to Parquet. Output file: ./parquet_data/RoleResourceAccess.parquet
CSV file ./csv_data/Subnets.csv has been successfully converted to Parquet. Output file: ./parquet_data/Subnets.parquet
CSV file ./csv_data/UserInternetGatewayAccess.csv has been successfully converted to Parquet. Output file: ./parquet_data/UserInternetGatewayAccess.parquet
CSV file ./csv_data/NetworkInterfaces.csv has been successfully converted to Parquet. Output file: ./parquet_data/NetworkInterfaces.parquet
CSV file ./csv_data/PrivateIPs.csv has been successfully converted to Parquet. Output file: ./parquet_data/PrivateIPs.parquet
CSV file ./csv_data/SubnetSecurityGroup.csv has been successfully converted to Parquet. Output file: ./parquet_data/SubnetSecurityGroup.parquet
CSV file ./csv_data/Roles.csv has been successfully converted to Parquet. Output file: ./parquet_data/Roles.parquet```


Create the temp directories to store it. They will be mounted as volumes into Kubernetes.

```bash
mkdir -p /tmp/puppygraph/warehouse
mkdir -p /tmp/puppygraph/notebooks
mkdir -p /tmp/puppygraph/parquet_data
```

## Create kind cluster ✅

```bash
❯ kind create cluster --name puppygraph --config manifests/kind-config.yaml
Creating cluster "puppygraph" ...
 ✓ Ensuring node image (kindest/node:v1.32.0) 🖼
 ✓ Preparing nodes 📦 📦  
 ✓ Writing configuration 📜 
 ✓ Starting control-plane 🕹️ 
 ✓ Installing CNI 🔌 
 ✓ Installing StorageClass 💾 
 ✓ Joining worker nodes 🚜 
Set kubectl context to "kind-puppygraph"
You can now use your cluster with:

kubectl cluster-info --context kind-puppygraph

Thanks for using kind! 😊
```

## Deploy PuppyGraph + Iceberg + Minio ✅

```bash
❯ kubectl apply -f manifests/k8s.yaml
namespace/puppy-iceberg created
service/spark-iceberg created
deployment.apps/spark-iceberg created
service/rest created
deployment.apps/iceberg-rest created
service/minio created
deployment.apps/minio created
deployment.apps/mc created
service/puppygraph created
deployment.apps/puppygraph created
persistentvolume/warehouse-volume created
persistentvolume/notebooks-volume created
persistentvolume/parquet-volume created
```

# Verify deployments ✅

```bash
❯ kubectl get deployment -n puppy-iceberg
NAME            READY   UP-TO-DATE   AVAILABLE   AGE
iceberg-rest    1/1     1            1           22m
mc              1/1     1            1           22m
minio           1/1     1            1           22m
puppygraph      1/1     1            1           22m
spark-iceberg   1/1     1            1           22m
```

# Verify services ✅

```bash
❯ kubectl get svc -n puppy-iceberg 
NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                                                         AGE
minio           ClusterIP   10.96.105.186   <none>        9000/TCP,9001/TCP                                               2m23s
puppygraph      ClusterIP   10.96.39.141    <none>        8081/TCP,8182/TCP,7687/TCP                                      2m23s
rest            ClusterIP   10.96.89.116    <none>        8181/TCP                                                        2m23s
spark-iceberg   NodePort    10.96.201.87    <none>        8888:30088/TCP,8080:30080/TCP,10000:30000/TCP,10001:30001/TCP   2m23s
````

# Connect to Puupygraph and Spark Iceberg ✅

Let's connect to the PuppyGraph Web UI. We need to port-forward the service to our local machine.

```bash
kubectl port-forward deploy/puppy 8081:8081 -n puppy-iceberg
```

This will bring up the login page.

![](images/login.png)

Use the default credentials - username: puppygraph, password: puppygraph123.

This will bring up the schema page.

![](images/schema.png)

The next step is to connect to Spark Iceberg.

```bash
❯ kubectl exec -it deploy/spark-iceberg -- spark-sql
Setting default log level to "WARN".
To adjust logging level use sc.setLogLevel(newLevel). For SparkR, use setLogLevel(newLevel).
25/02/02 00:32:37 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
25/02/02 00:32:38 WARN Utils: Service 'SparkUI' could not bind on port 4040. Attempting port 4041.
Spark Web UI available at http://spark-iceberg-5597fcb949-8xkm8:4041
Spark master: local[*], Application Id: local-1738456358826
spark-sql ()> 
```

To access the web UI we need to pord forward the pod.

```
kubectl port-forward pod/spark-iceberg-5597fcb949-8xkm8 4041:4041
Forwarding from 127.0.0.1:4041 -> 4041
Forwarding from [::1]:4041 -> 4041
```

![](spark-ui.png)

# Preparing the DB ❌

We need to create the tables in the Iceberg format. We will use the Spark Iceberg pod to do this.

Here is what it looks like in the original docker-compose setup from
PuppyGraph's [cloud scuirty graph demo](https://github.com/puppygraph/puppygraph-getting-started/blob/main/use-case-demos/cloud-security-graph-demo/README.md#data-import):

```bash
❯ sudo docker exec -it spark-iceberg spark-sql
Password:
Setting default log level to "WARN".
To adjust logging level use sc.setLogLevel(newLevel). For SparkR, use setLogLevel(newLevel).
25/02/02 02:01:09 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
25/02/02 02:01:10 WARN Utils: Service 'SparkUI' could not bind on port 4040. Attempting port 4041.
Spark Web UI available at http://bb5e53e5ed90:4041
Spark master: local[*], Application Id: local-1738461671048
spark-sql ()> CREATE DATABASE security_graph;
Time taken: 1.326 seconds

spark-sql ()> CREATE EXTERNAL TABLE security_graph.Users (
            >   user_id BIGINT,
            >   username STRING
            > ) USING iceberg;
Time taken: 0.949 seconds
spark-sql ()>
```

When we try this in the Kubernetes setup, we can create the security_Graph database successfully,
but creating the table fails:


```bash
❯ kubectl exec -it deploy/spark-iceberg -- spark-sql
Setting default log level to "WARN".
To adjust logging level use sc.setLogLevel(newLevel). For SparkR, use setLogLevel(newLevel).
25/02/02 02:17:53 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
25/02/02 02:17:54 WARN Utils: Service 'SparkUI' could not bind on port 4040. Attempting port 4041.
Spark Web UI available at http://spark-iceberg-5597fcb949-gfb6t:4041
Spark master: local[*], Application Id: local-1738462674045
spark-sql ()> CREATE DATABASE security_graph;
Time taken: 1.027 seconds

spark-sql ()> CREATE EXTERNAL TABLE security_graph.Users (
            >   user_id BIGINT,
            >   username STRING
            > ) USING iceberg;
25/02/02 02:18:26 ERROR SparkSQLDriver: Failed in [CREATE EXTERNAL TABLE security_graph.Users (
  user_id BIGINT,
  username STRING
) USING iceberg]
org.apache.iceberg.exceptions.ServiceFailureException: Server error: SdkClientException: Received an UnknownHostException when attempting to interact with a service. See cause for the exact endpoint that is failing to resolve. If this is happening on an endpoint that previously worked, there may be a network connectivity issue or your DNS cache could be storing endpoints for too long.
        at org.apache.iceberg.rest.ErrorHandlers$DefaultErrorHandler.accept(ErrorHandlers.java:217)
        at org.apache.iceberg.rest.ErrorHandlers$TableErrorHandler.accept(ErrorHandlers.java:118)
        at org.apache.iceberg.rest.ErrorHandlers$TableErrorHandler.accept(ErrorHandlers.java:102)
        at org.apache.iceberg.rest.HTTPClient.throwFailure(HTTPClient.java:201)
        at org.apache.iceberg.rest.HTTPClient.execute(HTTPClient.java:313)
        at org.apache.iceberg.rest.HTTPClient.execute(HTTPClient.java:252)
        at org.apache.iceberg.rest.HTTPClient.post(HTTPClient.java:358)
        at org.apache.iceberg.rest.RESTClient.post(RESTClient.java:112)
        at org.apache.iceberg.rest.RESTSessionCatalog$Builder.create(RESTSessionCatalog.java:673)
        at org.apache.iceberg.CachingCatalog$CachingTableBuilder.lambda$create$0(CachingCatalog.java:261)
        at org.apache.iceberg.shaded.com.github.benmanes.caffeine.cache.BoundedLocalCache.lambda$doComputeIfAbsent$14(BoundedLocalCache.java:2406)
        at java.base/java.util.concurrent.ConcurrentHashMap.compute(ConcurrentHashMap.java:1908)
        at org.apache.iceberg.shaded.com.github.benmanes.caffeine.cache.BoundedLocalCache.doComputeIfAbsent(BoundedLocalCache.java:2404)
        at org.apache.iceberg.shaded.com.github.benmanes.caffeine.cache.BoundedLocalCache.computeIfAbsent(BoundedLocalCache.java:2387)
        at org.apache.iceberg.shaded.com.github.benmanes.caffeine.cache.LocalCache.computeIfAbsent(LocalCache.java:108)
        at org.apache.iceberg.shaded.com.github.benmanes.caffeine.cache.LocalManualCache.get(LocalManualCache.java:62)
        at org.apache.iceberg.CachingCatalog$CachingTableBuilder.create(CachingCatalog.java:257)
        at org.apache.iceberg.spark.SparkCatalog.createTable(SparkCatalog.java:247)
        at org.apache.spark.sql.connector.catalog.TableCatalog.createTable(TableCatalog.java:200)
        at org.apache.spark.sql.execution.datasources.v2.CreateTableExec.run(CreateTableExec.scala:44)
        at org.apache.spark.sql.execution.datasources.v2.V2CommandExec.result$lzycompute(V2CommandExec.scala:43)
        at org.apache.spark.sql.execution.datasources.v2.V2CommandExec.result(V2CommandExec.scala:43)
        at org.apache.spark.sql.execution.datasources.v2.V2CommandExec.executeCollect(V2CommandExec.scala:49)
        at org.apache.spark.sql.execution.QueryExecution$$anonfun$eagerlyExecuteCommands$1.$anonfun$applyOrElse$1(QueryExecution.scala:107)
        at org.apache.spark.sql.execution.SQLExecution$.$anonfun$withNewExecutionId$6(SQLExecution.scala:125)
        at org.apache.spark.sql.execution.SQLExecution$.withSQLConfPropagated(SQLExecution.scala:201)
        at org.apache.spark.sql.execution.SQLExecution$.$anonfun$withNewExecutionId$1(SQLExecution.scala:108)
        at org.apache.spark.sql.SparkSession.withActive(SparkSession.scala:900)
        at org.apache.spark.sql.execution.SQLExecution$.withNewExecutionId(SQLExecution.scala:66)
        at org.apache.spark.sql.execution.QueryExecution$$anonfun$eagerlyExecuteCommands$1.applyOrElse(QueryExecution.scala:107)
        at org.apache.spark.sql.execution.QueryExecution$$anonfun$eagerlyExecuteCommands$1.applyOrElse(QueryExecution.scala:98)
        at org.apache.spark.sql.catalyst.trees.TreeNode.$anonfun$transformDownWithPruning$1(TreeNode.scala:461)
        at org.apache.spark.sql.catalyst.trees.CurrentOrigin$.withOrigin(origin.scala:76)
        at org.apache.spark.sql.catalyst.trees.TreeNode.transformDownWithPruning(TreeNode.scala:461)
        at org.apache.spark.sql.catalyst.plans.logical.LogicalPlan.org$apache$spark$sql$catalyst$plans$logical$AnalysisHelper$$super$transformDownWithPruning(LogicalPlan.scala:32)
        at org.apache.spark.sql.catalyst.plans.logical.AnalysisHelper.transformDownWithPruning(AnalysisHelper.scala:267)
        at org.apache.spark.sql.catalyst.plans.logical.AnalysisHelper.transformDownWithPruning$(AnalysisHelper.scala:263)
        at org.apache.spark.sql.catalyst.plans.logical.LogicalPlan.transformDownWithPruning(LogicalPlan.scala:32)
        at org.apache.spark.sql.catalyst.plans.logical.LogicalPlan.transformDownWithPruning(LogicalPlan.scala:32)
        at org.apache.spark.sql.catalyst.trees.TreeNode.transformDown(TreeNode.scala:437)
        at org.apache.spark.sql.execution.QueryExecution.eagerlyExecuteCommands(QueryExecution.scala:98)
        at org.apache.spark.sql.execution.QueryExecution.commandExecuted$lzycompute(QueryExecution.scala:85)
        at org.apache.spark.sql.execution.QueryExecution.commandExecuted(QueryExecution.scala:83)
        at org.apache.spark.sql.Dataset.<init>(Dataset.scala:220)
        at org.apache.spark.sql.Dataset$.$anonfun$ofRows$2(Dataset.scala:100)
        at org.apache.spark.sql.SparkSession.withActive(SparkSession.scala:900)
        at org.apache.spark.sql.Dataset$.ofRows(Dataset.scala:97)
        at org.apache.spark.sql.SparkSession.$anonfun$sql$4(SparkSession.scala:691)
        at org.apache.spark.sql.SparkSession.withActive(SparkSession.scala:900)
        at org.apache.spark.sql.SparkSession.sql(SparkSession.scala:682)
        at org.apache.spark.sql.SparkSession.sql(SparkSession.scala:713)
        at org.apache.spark.sql.SparkSession.sql(SparkSession.scala:744)
        at org.apache.spark.sql.SQLContext.sql(SQLContext.scala:651)
        at org.apache.spark.sql.hive.thriftserver.SparkSQLDriver.run(SparkSQLDriver.scala:68)
        at org.apache.spark.sql.hive.thriftserver.SparkSQLCLIDriver.processCmd(SparkSQLCLIDriver.scala:501)
        at org.apache.spark.sql.hive.thriftserver.SparkSQLCLIDriver.$anonfun$processLine$1(SparkSQLCLIDriver.scala:619)
        at org.apache.spark.sql.hive.thriftserver.SparkSQLCLIDriver.$anonfun$processLine$1$adapted(SparkSQLCLIDriver.scala:613)
        at scala.collection.Iterator.foreach(Iterator.scala:943)
        at scala.collection.Iterator.foreach$(Iterator.scala:943)
        at scala.collection.AbstractIterator.foreach(Iterator.scala:1431)
        at scala.collection.IterableLike.foreach(IterableLike.scala:74)
        at scala.collection.IterableLike.foreach$(IterableLike.scala:73)
        at scala.collection.AbstractIterable.foreach(Iterable.scala:56)
        at org.apache.spark.sql.hive.thriftserver.SparkSQLCLIDriver.processLine(SparkSQLCLIDriver.scala:613)
        at org.apache.spark.sql.hive.thriftserver.SparkSQLCLIDriver$.main(SparkSQLCLIDriver.scala:310)
        at org.apache.spark.sql.hive.thriftserver.SparkSQLCLIDriver.main(SparkSQLCLIDriver.scala)
        at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
        at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
        at java.base/jdk.internal.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
        at java.base/java.lang.reflect.Method.invoke(Method.java:566)
        at org.apache.spark.deploy.JavaMainApplication.start(SparkApplication.scala:52)
        at org.apache.spark.deploy.SparkSubmit.org$apache$spark$deploy$SparkSubmit$$runMain(SparkSubmit.scala:1029)
        at org.apache.spark.deploy.SparkSubmit.doRunMain$1(SparkSubmit.scala:194)
        at org.apache.spark.deploy.SparkSubmit.submit(SparkSubmit.scala:217)
        at org.apache.spark.deploy.SparkSubmit.doSubmit(SparkSubmit.scala:91)
        at org.apache.spark.deploy.SparkSubmit$$anon$2.doSubmit(SparkSubmit.scala:1120)
        at org.apache.spark.deploy.SparkSubmit$.main(SparkSubmit.scala:1129)
        at org.apache.spark.deploy.SparkSubmit.main(SparkSubmit.scala)
Server error: SdkClientException: Received an UnknownHostException when attempting to interact with a service. See cause for the exact endpoint that is failing to resolve. If this is happening on an endpoint that previously worked, there may be a network connectivity issue or your DNS cache could be storing endpoints for too long.
org.apache.iceberg.exceptions.ServiceFailureException: Server error: SdkClientException: Received an UnknownHostException when attempting to interact with a service. See cause for the exact endpoint that is failing to resolve. If this is happening on an endpoint that previously worked, there may be a network connectivity issue or your DNS cache could be storing endpoints for too long.
        at org.apache.iceberg.rest.ErrorHandlers$DefaultErrorHandler.accept(ErrorHandlers.java:217)
        at org.apache.iceberg.rest.ErrorHandlers$TableErrorHandler.accept(ErrorHandlers.java:118)
        at org.apache.iceberg.rest.ErrorHandlers$TableErrorHandler.accept(ErrorHandlers.java:102)
        at org.apache.iceberg.rest.HTTPClient.throwFailure(HTTPClient.java:201)
        at org.apache.iceberg.rest.HTTPClient.execute(HTTPClient.java:313)
        at org.apache.iceberg.rest.HTTPClient.execute(HTTPClient.java:252)
        at org.apache.iceberg.rest.HTTPClient.post(HTTPClient.java:358)
        at org.apache.iceberg.rest.RESTClient.post(RESTClient.java:112)
        at org.apache.iceberg.rest.RESTSessionCatalog$Builder.create(RESTSessionCatalog.java:673)
        at org.apache.iceberg.CachingCatalog$CachingTableBuilder.lambda$create$0(CachingCatalog.java:261)
        at org.apache.iceberg.shaded.com.github.benmanes.caffeine.cache.BoundedLocalCache.lambda$doComputeIfAbsent$14(BoundedLocalCache.java:2406)
        at java.base/java.util.concurrent.ConcurrentHashMap.compute(ConcurrentHashMap.java:1908)
        at org.apache.iceberg.shaded.com.github.benmanes.caffeine.cache.BoundedLocalCache.doComputeIfAbsent(BoundedLocalCache.java:2404)
        at org.apache.iceberg.shaded.com.github.benmanes.caffeine.cache.BoundedLocalCache.computeIfAbsent(BoundedLocalCache.java:2387)
        at org.apache.iceberg.shaded.com.github.benmanes.caffeine.cache.LocalCache.computeIfAbsent(LocalCache.java:108)
        at org.apache.iceberg.shaded.com.github.benmanes.caffeine.cache.LocalManualCache.get(LocalManualCache.java:62)
        at org.apache.iceberg.CachingCatalog$CachingTableBuilder.create(CachingCatalog.java:257)
        at org.apache.iceberg.spark.SparkCatalog.createTable(SparkCatalog.java:247)
        at org.apache.spark.sql.connector.catalog.TableCatalog.createTable(TableCatalog.java:200)
        at org.apache.spark.sql.execution.datasources.v2.CreateTableExec.run(CreateTableExec.scala:44)
        at org.apache.spark.sql.execution.datasources.v2.V2CommandExec.result$lzycompute(V2CommandExec.scala:43)
        at org.apache.spark.sql.execution.datasources.v2.V2CommandExec.result(V2CommandExec.scala:43)
        at org.apache.spark.sql.execution.datasources.v2.V2CommandExec.executeCollect(V2CommandExec.scala:49)
        at org.apache.spark.sql.execution.QueryExecution$$anonfun$eagerlyExecuteCommands$1.$anonfun$applyOrElse$1(QueryExecution.scala:107)
        at org.apache.spark.sql.execution.SQLExecution$.$anonfun$withNewExecutionId$6(SQLExecution.scala:125)
        at org.apache.spark.sql.execution.SQLExecution$.withSQLConfPropagated(SQLExecution.scala:201)
        at org.apache.spark.sql.execution.SQLExecution$.$anonfun$withNewExecutionId$1(SQLExecution.scala:108)
        at org.apache.spark.sql.SparkSession.withActive(SparkSession.scala:900)
        at org.apache.spark.sql.execution.SQLExecution$.withNewExecutionId(SQLExecution.scala:66)
        at org.apache.spark.sql.execution.QueryExecution$$anonfun$eagerlyExecuteCommands$1.applyOrElse(QueryExecution.scala:107)
        at org.apache.spark.sql.execution.QueryExecution$$anonfun$eagerlyExecuteCommands$1.applyOrElse(QueryExecution.scala:98)
        at org.apache.spark.sql.catalyst.trees.TreeNode.$anonfun$transformDownWithPruning$1(TreeNode.scala:461)
        at org.apache.spark.sql.catalyst.trees.CurrentOrigin$.withOrigin(origin.scala:76)
        at org.apache.spark.sql.catalyst.trees.TreeNode.transformDownWithPruning(TreeNode.scala:461)
        at org.apache.spark.sql.catalyst.plans.logical.LogicalPlan.org$apache$spark$sql$catalyst$plans$logical$AnalysisHelper$$super$transformDownWithPruning(LogicalPlan.scala:32)
        at org.apache.spark.sql.catalyst.plans.logical.AnalysisHelper.transformDownWithPruning(AnalysisHelper.scala:267)
        at org.apache.spark.sql.catalyst.plans.logical.AnalysisHelper.transformDownWithPruning$(AnalysisHelper.scala:263)
        at org.apache.spark.sql.catalyst.plans.logical.LogicalPlan.transformDownWithPruning(LogicalPlan.scala:32)
        at org.apache.spark.sql.catalyst.plans.logical.LogicalPlan.transformDownWithPruning(LogicalPlan.scala:32)
        at org.apache.spark.sql.catalyst.trees.TreeNode.transformDown(TreeNode.scala:437)
        at org.apache.spark.sql.execution.QueryExecution.eagerlyExecuteCommands(QueryExecution.scala:98)
        at org.apache.spark.sql.execution.QueryExecution.commandExecuted$lzycompute(QueryExecution.scala:85)
        at org.apache.spark.sql.execution.QueryExecution.commandExecuted(QueryExecution.scala:83)
        at org.apache.spark.sql.Dataset.<init>(Dataset.scala:220)
        at org.apache.spark.sql.Dataset$.$anonfun$ofRows$2(Dataset.scala:100)
        at org.apache.spark.sql.SparkSession.withActive(SparkSession.scala:900)
        at org.apache.spark.sql.Dataset$.ofRows(Dataset.scala:97)
        at org.apache.spark.sql.SparkSession.$anonfun$sql$4(SparkSession.scala:691)
        at org.apache.spark.sql.SparkSession.withActive(SparkSession.scala:900)
        at org.apache.spark.sql.SparkSession.sql(SparkSession.scala:682)
        at org.apache.spark.sql.SparkSession.sql(SparkSession.scala:713)
        at org.apache.spark.sql.SparkSession.sql(SparkSession.scala:744)
        at org.apache.spark.sql.SQLContext.sql(SQLContext.scala:651)
        at org.apache.spark.sql.hive.thriftserver.SparkSQLDriver.run(SparkSQLDriver.scala:68)
        at org.apache.spark.sql.hive.thriftserver.SparkSQLCLIDriver.processCmd(SparkSQLCLIDriver.scala:501)
        at org.apache.spark.sql.hive.thriftserver.SparkSQLCLIDriver.$anonfun$processLine$1(SparkSQLCLIDriver.scala:619)
        at org.apache.spark.sql.hive.thriftserver.SparkSQLCLIDriver.$anonfun$processLine$1$adapted(SparkSQLCLIDriver.scala:613)
        at scala.collection.Iterator.foreach(Iterator.scala:943)
        at scala.collection.Iterator.foreach$(Iterator.scala:943)
        at scala.collection.AbstractIterator.foreach(Iterator.scala:1431)
        at scala.collection.IterableLike.foreach(IterableLike.scala:74)
        at scala.collection.IterableLike.foreach$(IterableLike.scala:73)
        at scala.collection.AbstractIterable.foreach(Iterable.scala:56)
        at org.apache.spark.sql.hive.thriftserver.SparkSQLCLIDriver.processLine(SparkSQLCLIDriver.scala:613)
        at org.apache.spark.sql.hive.thriftserver.SparkSQLCLIDriver$.main(SparkSQLCLIDriver.scala:310)
        at org.apache.spark.sql.hive.thriftserver.SparkSQLCLIDriver.main(SparkSQLCLIDriver.scala)
        at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
        at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
        at java.base/jdk.internal.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
        at java.base/java.lang.reflect.Method.invoke(Method.java:566)
        at org.apache.spark.deploy.JavaMainApplication.start(SparkApplication.scala:52)
        at org.apache.spark.deploy.SparkSubmit.org$apache$spark$deploy$SparkSubmit$$runMain(SparkSubmit.scala:1029)
        at org.apache.spark.deploy.SparkSubmit.doRunMain$1(SparkSubmit.scala:194)
        at org.apache.spark.deploy.SparkSubmit.submit(SparkSubmit.scala:217)
        at org.apache.spark.deploy.SparkSubmit.doSubmit(SparkSubmit.scala:91)
        at org.apache.spark.deploy.SparkSubmit$$anon$2.doSubmit(SparkSubmit.scala:1120)
        at org.apache.spark.deploy.SparkSubmit$.main(SparkSubmit.scala:1129)
        at org.apache.spark.deploy.SparkSubmit.main(SparkSubmit.scala)
spark-sql ()> 
```

The code for the REST catalog server is here:
https://github.com/databricks/iceberg-rest-image/blob/master/src/main/java/org/apache/iceberg/rest/RESTCatalogServer.java

In the logs of iceberg-rest we see the following error:

```
❯ k logs deploy/iceberg-rest | rg minio
2025-02-02T07:37:17.281 INFO  [org.apache.iceberg.rest.RESTCatalogServer] - Creating catalog with properties: {jdbc.password=password, s3.endpoint=http://minio.puppy-iceberg.svc.cluster.local:9000, jdbc.user=user, io-impl=org.apache.iceberg.aws.s3.S3FileIO, catalog-impl=org.apache.iceberg.jdbc.JdbcCatalog, jdbc.schema-version=V1, warehouse=s3://warehouse/, uri=jdbc:sqlite:file:/tmp/iceberg_rest_mode=memory, s3.path.style.access=true}
Caused by: software.amazon.awssdk.core.exception.SdkClientException: Unable to execute HTTP request: warehouse.minio.puppy-iceberg.svc.cluster.local
	Suppressed: software.amazon.awssdk.core.exception.SdkClientException: Request attempt 1 failure: Unable to execute HTTP request: warehouse.minio.puppy-iceberg.svc.cluster.local: Name or service not known
	Suppressed: software.amazon.awssdk.core.exception.SdkClientException: Request attempt 2 failure: Unable to execute HTTP request: warehouse.minio.puppy-iceberg.svc.cluster.local
	Suppressed: software.amazon.awssdk.core.exception.SdkClientException: Request attempt 3 failure: Unable to execute HTTP request: warehouse.minio.puppy-iceberg.svc.cluster.local
Caused by: java.net.UnknownHostException: warehouse.minio.puppy-iceberg.svc.cluster.local```
```

The issue is that the REST catalog server is trying to connect to the Minio service using the wrong URL: 
warehouse.minio.puppy-iceberg.svc.cluster.local

It should be just `minio.puppy-iceberg.svc.cluster.local`

This is a virtual domain access style. We need the path access style.

All the attmpts to force path access style failed 😢. 

# Hacking Core DNS

First get the IP address of minio service

```bash
❯ kubectl get svc minio -o yaml | yq .spec.clusterIP
10.96.50.71
```

Let's add this to the CoreDNS configmap:

```yaml
        template IN A *.minio {
          match ^(.+)\.minio\.$
          answer "{{ .Name }} 60 IN A 10.96.50.71"
        }
```        

Then, restarting the core DNS service

```
❯ kubectl rollout restart deploy/coredns -n kube-system
deployment.apps/coredns restarted
```

hmmmm.... that didn't work either ¯\_(ツ)_/¯


# Switch backend to Hadoop

This is much simpler. We get rid of minio + mc and use local file system on the rest catlog server.

Now, creating the database fails:
```
spark-sql ()> CREATE DATABASE security_graph;
25/02/02 08:39:10 ERROR SparkSQLDriver: Failed in [CREATE DATABASE security_graph]
org.apache.iceberg.exceptions.RESTException: Unable to process: Cannot create namespace security_graph: metadata is not supported
```

That's OK. The catalog server treats the DB as a namespace we can just skip this step and create the tables.

For example:
```
CREATE EXTERNAL  TABLE IF NOT EXISTS security_graph.Users (
  user_id BIGINT,
  username STRING
) USING iceberg;
```

To create all the tables run the script:

```bash
./prepare-db.sh
```

All the tables are created successfully, but inserting the data fails. It looks like something is hard-coded to use s3 storage, so it fails for the Hadoop file system backend.

```
spark-sql ()> INSERT INTO security_graph.Users
            > SELECT * FROM parquet.`/parquet_data/Users.parquet`;
25/02/02 21:13:18 ERROR Executor: Exception in task 0.0 in stage 1.0 (TID 1)
org.apache.iceberg.exceptions.ValidationException: Invalid S3 URI, cannot determine scheme: file:/data/warehouse/security_graph/Users/data/00000-1-d7858365-5038-44c2-823d-024e1eb22be1-0-00001.parquet
	at org.apache.iceberg.exceptions.ValidationException.check(ValidationException.java:49)
	at org.apache.iceberg.aws.s3.S3URI.<init>(S3URI.java:72)
	at org.apache.iceberg.aws.s3.S3OutputFile.fromLocation(S3OutputFile.java:42)
	at org.apache.iceberg.aws.s3.S3FileIO.newOutputFile(S3FileIO.java:135)
	at org.apache.iceberg.io.OutputFileFactory.newOutputFile(OutputFileFactory.java:105)
```

Looks like S3 is a default
```
❯ kubectl exec -it deploy/spark-iceberg -- cat /opt/spark/conf/spark-defaults.conf | grep -i iceberg
spark.sql.extensions                   org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions
spark.sql.catalog.demo                 org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.demo.io-impl         org.apache.iceberg.aws.s3.S3FileIO
spark.eventLog.dir                     /home/iceberg/spark-events
spark.history.fs.logDirectory          /home/iceberg/spark-events
```

This is coming from here:


https://github.com/databricks/docker-spark-iceberg/blob/main/spark/spark-defaults.conf#L26

```
spark.sql.extensions                   org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions
spark.sql.catalog.demo                 org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.demo.type            rest
spark.sql.catalog.demo.uri             http://rest:8181
spark.sql.catalog.demo.io-impl         org.apache.iceberg.aws.s3.S3FileIO
spark.sql.catalog.demo.warehouse       s3://warehouse/wh/
spark.sql.catalog.demo.s3.endpoint     http://minio:9000
spark.sql.defaultCatalog               demo
spark.eventLog.enabled                 true
spark.eventLog.dir                     /home/iceberg/spark-events
spark.history.fs.logDirectory          /home/iceberg/spark-events
spark.sql.catalogImplementation        in-memory
```

Let's fix it:

```bash
❯ kubectl exec -it deploy/spark-iceberg -- \
  sed -i -e 's|spark.sql.catalog.demo.warehouse\s\+s3://warehouse/wh/|spark.sql.catalog.demo.warehouse file:/data/warehouse|' \
         -e 's|spark.sql.catalog.demo.io-impl\s\+org.apache.iceberg.aws.s3.S3FileIO|spark.sql.catalog.demo.io-impl org.apache.iceberg.hadoop.HadoopFileIO|' \
  /opt/spark/conf/spark-defaults.conf
```

We can also remove the S3 endpoint, which is not needed anymore:

```
❯ kubectl exec -it deploy/spark-iceberg -- \
  sed -i '/spark.sql.catalog.demo.s3.endpoint/d' /opt/spark/conf/spark-defaults.conf
```

Verify it was updated correctly:

```
❯ kubectl exec -it deploy/spark-iceberg -- cat /opt/spark/conf/spark-defaults.conf | rg spark
# Default system properties included when running spark-submit.
spark.sql.extensions                   org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions
spark.sql.catalog.demo                 org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.demo.type            rest
spark.sql.catalog.demo.uri             http://rest:8181
spark.sql.catalog.demo.io-impl org.apache.iceberg.hadoop.HadoopFileIO
spark.sql.catalog.demo.warehouse file:/data/warehouse
spark.sql.defaultCatalog               demo
spark.eventLog.enabled                 true
spark.eventLog.dir                     /home/iceberg/spark-events
spark.history.fs.logDirectory          /home/iceberg/spark-events
spark.sql.catalogImplementation        in-memory
```

Now we can try to insert the data again:

```
❯ ./prepare_db.sh
Finding pod for deployment spark-iceberg...
Pod found: spark-iceberg-5597fcb949-5l78c
Copying security_graph.sql to pod spark-iceberg-5597fcb949-5l78c at /tmp/security_graph.sql...
File copied successfully.
Copying parquet_data to pod spark-iceberg-5597fcb949-5l78c at /...
Directory copied successfully.
Executing security_graph.sql on pod spark-iceberg-5597fcb949-5l78c using spark-sql...
Setting default log level to "WARN".
To adjust logging level use sc.setLogLevel(newLevel). For SparkR, use setLogLevel(newLevel).
25/02/02 22:33:42 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
25/02/02 22:33:43 WARN Utils: Service 'SparkUI' could not bind on port 4040. Attempting port 4041.
Spark Web UI available at http://spark-iceberg-5597fcb949-5l78c:4041
Spark master: local[*], Application Id: local-1738535623310
Time taken: 1.219 seconds
Time taken: 0.029 seconds
Time taken: 0.02 seconds
Time taken: 0.017 seconds
Time taken: 0.018 seconds
Time taken: 0.016 seconds
Time taken: 0.015 seconds
Time taken: 0.018 seconds
Time taken: 0.016 seconds
Time taken: 0.015 seconds
Time taken: 0.023 seconds
Time taken: 0.012 seconds
Time taken: 0.012 seconds
Time taken: 0.012 seconds
Time taken: 0.012 seconds
Time taken: 0.018 seconds
Time taken: 0.013 seconds
Time taken: 1.746 seconds
Time taken: 0.225 seconds
Time taken: 0.215 seconds
Time taken: 0.199 seconds
Time taken: 0.172 seconds
Time taken: 0.17 seconds
Time taken: 0.148 seconds
Time taken: 0.171 seconds
Time taken: 0.203 seconds
Time taken: 0.152 seconds
Time taken: 0.132 seconds
Time taken: 0.127 seconds
Time taken: 0.123 seconds
Time taken: 0.158 seconds
Time taken: 0.137 seconds
Time taken: 0.164 seconds
Time taken: 0.145 seconds
SQL script executed successfully!
```




# Reference

[Recreating Wiz's Security Graph with PuppyGraph](https://www.puppygraph.com/blog/wiz-security-graph)
[Cloud Security Graph Demo](https://github.com/puppygraph/puppygraph-getting-started/blob/main/use-case-demos/cloud-security-graph-demo/README.md#data-import)