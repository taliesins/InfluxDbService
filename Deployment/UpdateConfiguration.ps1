[CmdletBinding()]
param(
	[string] $environmentConfigurationFilePath = (Join-Path (Split-Path -parent $MyInvocation.MyCommand.Definition) "deployment_configuration.json" ),
	[string] $productConfigurationFilePath = (Join-Path (Split-Path -parent $MyInvocation.MyCommand.Definition) "configuration.xml" )
)

$scriptPath = Split-Path -parent $MyInvocation.MyCommand.Definition
Import-Module $scriptPath\PowershellModules\CommonDeploy.psm1 -Force

$rootPath = Split-Path -parent $scriptPath

$e = $environmentConfiguration = Read-ConfigurationTokens $environmentConfigurationFilePath
$p = $productConfiguration = Get-Configuration $environmentConfigurationFilePath $productConfigurationFilePath

$confileFilePath = "$rootPath\influxdb.conf"

$config = @"
### Welcome to the InfluxDB configuration file.

# The values in this file override the default values used by the system if
# a config option is not specified. The commented out lines are the configuration
# field and the default value used. Uncommenting a line and changing the value
# will change the value used at runtime when the process is restarted.

# Once every 24 hours InfluxDB will report usage data to usage.influxdata.com
# The data includes a random ID, os, arch, version, the number of series and other
# usage data. No data from user databases is ever transmitted.
# Change this option to true to disable reporting.
# reporting-disabled = false

# Bind address to use for the RPC service for backup and restore.
bind-address = "$($e.BindAddress)"

###
### [meta]
###
### Controls the parameters for the Raft consensus group that stores metadata
### about the InfluxDB cluster.
###

[meta]
  # Where the metadata/raft database is stored
  dir = "$($e.MetaDir)"

  # Automatically create a default retention policy when creating a database.
  retention-autocreate = $($e.MetaRetentionAutocreate)

  # If log messages are printed for the meta service
  logging-enabled = $($e.MetaLoggingEnabled)

###
### [data]
###
### Controls where the actual shard data for InfluxDB lives and how it is
### flushed from the WAL. "dir" may need to be changed to a suitable place
### for your system, but the WAL settings are an advanced configuration. The
### defaults should work for most systems.
###

[data]
  # The directory where the TSM storage engine stores TSM files.
  dir = "$($e.DataDir)"

  # The directory where the TSM storage engine stores WAL files.
  wal-dir = "$($e.DataWalDir)"

  # The amount of time that a write will wait before fsyncing.  A duration
  # greater than 0 can be used to batch up multiple fsync calls.  This is useful for slower
  # disks or when WAL write contention is seen.  A value of 0s fsyncs every write to the WAL.
  # Values in the range of 0-100ms are recommended for non-SSD disks.
  wal-fsync-delay = "$($e.DataWalFsyncDelay)"


  # The type of shard index to use for new shards.  The default is an in-memory index that is
  # recreated at startup.  A value of "tsi1" will use a disk based index that supports higher
  # cardinality datasets.
  index-version = "$($e.DataIndexVersion)"

  # Trace logging provides more verbose output around the tsm engine. Turning
  # this on can provide more useful output for debugging tsm engine issues.
  trace-logging-enabled = $($e.DataTraceLoggingEnabled)

  # Whether queries should be logged before execution. Very useful for troubleshooting, but will
  # log any sensitive data contained within a query.
  query-log-enabled = $($e.DataQueryLogEnabled)

  # Settings for the TSM engine

  # CacheMaxMemorySize is the maximum size a shard's cache can
  # reach before it starts rejecting writes.
  cache-max-memory-size = $($e.DataCacheMaxMemorySize)

  # CacheSnapshotMemorySize is the size at which the engine will
  # snapshot the cache and write it to a TSM file, freeing up memory
  cache-snapshot-memory-size = $($e.DataCacheSnapshotMemorySize)

  # CacheSnapshotWriteColdDuration is the length of time at
  # which the engine will snapshot the cache and write it to
  # a new TSM file if the shard hasn't received writes or deletes
  cache-snapshot-write-cold-duration = "$($e.DataCacheSnapshotWriteColdDuration)"

  # CompactFullWriteColdDuration is the duration at which the engine
  # will compact all TSM files in a shard if it hasn't received a
  # write or delete
  compact-full-write-cold-duration = "$($e.DataCompactFullWriteColdDuration)"

  # The maximum number of concurrent full and level compactions that can run at one time.  A
  # value of 0 results in runtime.GOMAXPROCS(0) used at runtime.  This setting does not apply
  # to cache snapshotting.
  max-concurrent-compactions = $($e.DataMaxConcurrentCompactions)

  # The maximum series allowed per database before writes are dropped.  This limit can prevent
  # high cardinality issues at the database level.  This limit can be disabled by setting it to
  # 0.
  max-series-per-database = $($e.DataMaxSeriesPerDatabase)

  # The maximum number of tag values per tag that are allowed before writes are dropped.  This limit
  # can prevent high cardinality tag values from being written to a measurement.  This limit can be
  # disabled by setting it to 0.
  max-values-per-tag = $($e.DataMaxValuesPerTag)

###
### [coordinator]
###
### Controls the clustering service configuration.
###

[coordinator]
  # The default time a write request will wait until a "timeout" error is returned to the caller.
  write-timeout = "$($e.CoordinatorWriteTimeout)"

  # The maximum number of concurrent queries allowed to be executing at one time.  If a query is
  # executed and exceeds this limit, an error is returned to the caller.  This limit can be disabled
  # by setting it to 0.
  max-concurrent-queries = $($e.CoordinatorMaxConcurrentQueries)

  # The maximum time a query will is allowed to execute before being killed by the system.  This limit
  # can help prevent run away queries.  Setting the value to 0 disables the limit.
  query-timeout = "$($e.CoordinatorQueryTimeout)"

  # The time threshold when a query will be logged as a slow query.  This limit can be set to help
  # discover slow or resource intensive queries.  Setting the value to 0 disables the slow query logging.
  log-queries-after = "$($e.CoordinatorLogQueriesAfter)"

  # The maximum number of points a SELECT can process.  A value of 0 will make
  # the maximum point count unlimited.  This will only be checked every 10 seconds so queries will not
  # be aborted immediately when hitting the limit.
  max-select-point = $($e.CoordinatorMaxSelectPoint)

  # The maximum number of series a SELECT can run.  A value of 0 will make the maximum series
  # count unlimited.
  max-select-series = $($e.CoordinatorMaxSelectSeries)

  # The maxium number of group by time bucket a SELECT can create.  A value of zero will max the maximum
  # number of buckets unlimited.
  max-select-buckets = $($e.CoordinatorMaxSelectBuckets)

###
### [retention]
###
### Controls the enforcement of retention policies for evicting old data.
###

[retention]
  # Determines whether retention policy enforcement enabled.
  enabled = $($e.RetentionEnabled)

  # The interval of time when retention policy enforcement checks run.
  check-interval = "$($e.RetentionCheckInterval)"

###
### [shard-precreation]
###
### Controls the precreation of shards, so they are available before data arrives.
### Only shards that, after creation, will have both a start- and end-time in the
### future, will ever be created. Shards are never precreated that would be wholly
### or partially in the past.

[shard-precreation]
  # Determines whether shard pre-creation service is enabled.
  enabled = $($e.ShardPrecreationEnabled)

  # The interval of time when the check to pre-create new shards runs.
  check-interval = "$($e.ShardPrecreationCheckInterval)"

  # The default period ahead of the endtime of a shard group that its successor
  # group is created.
  advance-period = "$($e.ShardPrecreationAdvancePeriod)"

###
### Controls the system self-monitoring, statistics and diagnostics.
###
### The internal database for monitoring data is created automatically if
### if it does not already exist. The target retention within this database
### is called 'monitor' and is also created with a retention period of 7 days
### and a replication factor of 1, if it does not exist. In all cases the
### this retention policy is configured as the default for the database.

[monitor]
  # Whether to record statistics internally.
  store-enabled = $($e.MonitorStoreEnabled)

  # The destination database for recorded statistics
  store-database = "$($e.MonitorStoreDatabase)"

  # The interval at which to record statistics
  store-interval = "$($e.MonitorStoreInterval)"

###
### [http]
###
### Controls how the HTTP endpoints are configured. These are the primary
### mechanism for getting data into and out of InfluxDB.
###

[http]
  # Determines whether HTTP endpoint is enabled.
  enabled = $($e.HttpEnabled)

  # The bind address used by the HTTP service.
  bind-address = "$($e.HttpBindAddress)"

  # Determines whether user authentication is enabled over HTTP/HTTPS.
  auth-enabled = $($e.HttpAuthEnabled)

  # The default realm sent back when issuing a basic auth challenge.
  realm = "$($e.HttpRealm)"

  # Determines whether HTTP request logging is enabled.
  log-enabled = $($e.HttpLogEnabled)

  # Determines whether detailed write logging is enabled.
  write-tracing = $($e.HttpWriteTracing)

  # Determines whether the pprof endpoint is enabled.  This endpoint is used for
  # troubleshooting and monitoring.
  pprof-enabled = $($e.HttpPprofEnabled)

  # Determines whether HTTPS is enabled.
  https-enabled = $($e.HttpsEnabled)

  # The SSL certificate to use when HTTPS is enabled.
  https-certificate = "$($e.HttpsCertificate)"

  # Use a separate private key location.
  https-private-key = "$($e.HttpsPrivateKey)"

  # The JWT auth shared secret to validate requests using JSON web tokens.
  shared-secret = "$($e.HttpSharedSecret)"

  # The default chunk size for result sets that should be chunked.
  max-row-limit = $($e.HttpMaxRowLimit)

  # The maximum number of HTTP connections that may be open at once.  New connections that
  # would exceed this limit are dropped.  Setting this value to 0 disables the limit.
  max-connection-limit = $($e.HttpMaxConnectionLimit)

  # Enable http service over unix domain socket
  unix-socket-enabled = $($e.HttpUnixSocketEnabled)

  # The path of the unix domain socket.
  bind-socket = "$($e.HttpBindSocket)"

###
### [subscriber]
###
### Controls the subscriptions, which can be used to fork a copy of all data
### received by the InfluxDB host.
###

[subscriber]
  # Determines whether the subscriber service is enabled.
  enabled = $($e.SubscriberEnabled)

  # The default timeout for HTTP writes to subscribers.
  http-timeout = "$($e.SubscriberHttpTimeout)"

  # Allows insecure HTTPS connections to subscribers.  This is useful when testing with self-
  # signed certificates.
  insecure-skip-verify = $($e.SubscriberInsecureSkipVerify)

  # The path to the PEM encoded CA certs file. If the empty string, the default system certs will be used
  ca-certs = "$($e.SubscriberCaCerts)"

  # The number of writer goroutines processing the write channel.
  write-concurrency = $($e.SubscriberWriteConcurrency)

  # The number of in-flight writes buffered in the write channel.
  write-buffer-size = $($e.SubscriberWriteBufferSize)


###
### [[graphite]]
###
### Controls one or many listeners for Graphite data.
###

[[graphite]]
  # Determines whether the graphite endpoint is enabled.
  enabled = $($e.GraphiteEnabled)
  database = "$($e.GraphiteDatabase)"
  retention-policy = "$($e.GraphiteRetentionPolicy)"
  bind-address = "$($e.GraphiteBindAddress)"
  protocol = "$($e.GraphiteProtocol)"
  consistency-level = "$($e.GraphiteConsistencyLevel)"

  # These next lines control how batching works. You should have this enabled
  # otherwise you could get dropped metrics or poor performance. Batching
  # will buffer points in memory if you have many coming in.

  # Flush if this many points get buffered
  batch-size = $($e.GraphiteBatchSize)

  # number of batches that may be pending in memory
  batch-pending = $($e.GraphiteBatchPending)

  # Flush at least this often even if we haven't hit buffer limit
  batch-timeout = "$($e.GraphiteBatchTimeout)"

  # UDP Read buffer size, 0 means OS default. UDP listener will fail if set above OS max.
  udp-read-buffer = $($e.GraphiteUdpReadBuffer)

  ### This string joins multiple matching 'measurement' values providing more control over the final measurement name.
  separator = "$($e.GraphiteSeparator)"

  ### Default tags that will be added to all metrics.  These can be overridden at the template level
  ### or by tags extracted from metric
  # tags = ["region=us-east", "zone=1c"]

  ### Each template line requires a template pattern.  It can have an optional
  ### filter before the template and separated by spaces.  It can also have optional extra
  ### tags following the template.  Multiple tags should be separated by commas and no spaces
  ### similar to the line protocol format.  There can be only one default template.
  # templates = [
  #   "*.app env.service.resource.measurement",
  #   # Default template
  #   "server.*",
  # ]

###
### [collectd]
###
### Controls one or many listeners for collectd data.
###

[[collectd]]
  enabled = $($e.CollectdEnabled)
  bind-address = "$($e.CollectdBindAddress)"
  database = "$($e.CollectdDatabase)"
  retention-policy = "$($e.CollectdRetentionPolicy)"
  #
  # The collectd service supports either scanning a directory for multiple types
  # db files, or specifying a single db file.
  typesdb = "$($e.CollectdTypesdb)"
  #
  security-level = "$($e.CollectdSecurityLevel)"
  auth-file = "$($e.CollectdAuthFile)"

  # These next lines control how batching works. You should have this enabled
  # otherwise you could get dropped metrics or poor performance. Batching
  # will buffer points in memory if you have many coming in.

  # Flush if this many points get buffered
  batch-size = $($e.CollectdBatchSize)

  # Number of batches that may be pending in memory
  batch-pending = $($e.CollectdBatchPending)

  # Flush at least this often even if we haven't hit buffer limit
  batch-timeout = "$($e.CollectdBatchTimeout)"

  # UDP Read buffer size, 0 means OS default. UDP listener will fail if set above OS max.
  read-buffer = $($e.CollectdReadBuffer)

###
### [opentsdb]
###
### Controls one or many listeners for OpenTSDB data.
###

[[opentsdb]]
  enabled = $($e.OpentsdbEnabled)
  bind-address = "$($e.OpentsdbBindAddress)"
  database = "$($e.OpentsdbDatabase)"
  retention-policy = "$($e.OpentsdbRetentionPolicy)"
  consistency-level = "$($e.OpentsdbConsistencyLevel)"
  tls-enabled = $($e.OpentsdbTlsEnabled)
  certificate= "$($e.OpentsdbCertificate)"

  # Log an error for every malformed point.
  log-point-errors = $($e.OpentsdbLogPointErrors)

  # These next lines control how batching works. You should have this enabled
  # otherwise you could get dropped metrics or poor performance. Only points
  # metrics received over the telnet protocol undergo batching.

  # Flush if this many points get buffered
  batch-size = $($e.OpentsdbBatchSize)

  # Number of batches that may be pending in memory
  batch-pending = $($e.OpentsdbBatchPending)

  # Flush at least this often even if we haven't hit buffer limit
  batch-timeout = "$($e.OpentsdbBatchTimeout)"

###
### [[udp]]
###
### Controls the listeners for InfluxDB line protocol data via UDP.
###

[[udp]]
  enabled = $($e.UdpEnabled)
  bind-address = "$($e.UdpBindAddress)"
  database = "$($e.UdpDatabase)"
  retention-policy = "$($e.UdpRetentionPolicy)"

  # These next lines control how batching works. You should have this enabled
  # otherwise you could get dropped metrics or poor performance. Batching
  # will buffer points in memory if you have many coming in.

  # Flush if this many points get buffered
  batch-size = $($e.UdpBatchSize)

  # Number of batches that may be pending in memory
  batch-pending = $($e.UdpBatchPending)

  # Will flush at least this often even if we haven't hit buffer limit
  batch-timeout = "$($e.UdpBatchTimeout)"

  # UDP Read buffer size, 0 means OS default. UDP listener will fail if set above OS max.
  read-buffer = $($e.UdpReadBuffer)

###
### [continuous_queries]
###
### Controls how continuous queries are run within InfluxDB.
###

[continuous_queries]
  # Determines whether the continuous query service is enabled.
  enabled = $($e.ContinuousQueriesEnabled)

  # Controls whether queries are logged when executed by the CQ service.
  log-enabled = $($e.ContinuousQueriesLogEnabled)

  # interval for how often continuous queries will be checked if they need to run
  run-interval = "$($e.ContinuousQueriesRunInterval)"

"@

Set-Content -Path $confileFilePath -Value $config