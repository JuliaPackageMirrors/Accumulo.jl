# clones a table
# If the flush option is not enabled, then any data the source table currently has in memory will not exist in the clone.
# A cloned table copies the configuration of the source table.
# However the permissions of the source table are not copied to the clone.
# After a clone is created, only the user that created the clone can read and write to it.
function table_clone(session::AccumuloSession, tablename::AbstractString, newtablename::AbstractString; flush::Bool=true, set_properties::Dict=Dict(), exclude_properties::SET=())
    setprops = Dict{UTF8String,UTF8String}([utf8(string(n))=>utf8(string(v)) for (n,v) in set_properties]...)
    exclprops = Set(UTF8String[utf8(string(x)) for x in exclude_properties])
    cloneTable(client(session), handle(session), utf8(tablename), utf8(newtablename), flush, setprops, exclprops)
end

# create, delete, rename tables
#
# When a table is created, by default it is configured to use the VersioningIterator and keep one version. A table can be created without the VersioningIterator.
# Accumulo can be configured to return the top k versions, or versions later than a given date. The default is to return the one most recent version.
# The version policy can be changed by changing the VersioningIterator options with the `config` api.
#
# Using logical timestamps ensures that timestamps set by Accumulo always move forward. This helps avoid problems caused by TabletServers that have different time settings.
# The default is to use milliseconds as timestamp.
function table_create(session::AccumuloSession, tablename::AbstractString; versioning::Bool=true, logical_timestamp::Bool=false)
    time_type = logical_timestamp ? TimeType.LOGICAL : TimeType.MILLIS
    createTable(client(session), handle(session), utf8(tablename), versioning, time_type)
end
table_delete(session::AccumuloSession, tablename::AbstractString) = deleteTable(client(session), handle(session), utf8(tablename))
table_rename(session::AccumuloSession, tablename::AbstractString, new_name::AbstractString) = renameTable(client(session), handle(session), utf8(tablename), utf8(new_name))

# prints how much space, in bytes, is used by files referenced by a table.  When multiple tables are specified it prints how much space, in bytes, is used by files shared between tables, if any.
function table_du(session::AccumuloSession, tables::AbstractString...)
    tableset = Set(UTF8String[utf8(string(x)) for x in tables])
    usage = getDiskUsage(client(session), handle(session), tableset)
    (usage[1]).usage
end

table_exists(session::AccumuloSession, table::AbstractString) = tableExists(client(session), handle(session), utf8(table))

# get or set table specific properties
table_config(session::AccumuloSession, tablename::AbstractString) = getTableProperties(client(session), handle(session), utf8(tablename))
table_config!(session::AccumuloSession, tablename::AbstractString, property::AbstractString, value::AbstractString) = setTableProperty(client(session), handle(session), utf8(tablename), utf8(property), utf8(value))

# limit versions in a table
function table_versions!(session::AccumuloSession, tablename::AbstractString, nversions::Integer)
    (nversions > 0) || error("at least 1 version required")
    viter = iter("vers", "org.apache.accumulo.core.iterators.user.VersioningIterator", 10, Dict("maxVersions"=>nversions))
    add_iter(session, tablename, viter, (IteratorScope.MINC, IteratorScope.MAJC, IteratorScope.SCAN))
end

# import/export tables
#
# Accumulo supports exporting tables for the purpose of copying tables to another cluster.
# Exporting and importing tables preserves the tables configuration, splits, and logical time.
# Tables are exported and then copied via the hadoop distcp command.
# To export a table, it must be offline and stay offline while discp runs. The reason it needs to stay offline is to prevent files from being deleted.
# A table can be cloned and the clone taken offline inorder to avoid losing access to the table.
table_export(session::AccumuloSession, tablename::AbstractString, export_dir::AbstractString) = exportTable(client(session), handle(session), utf8(tablename), utf8(export_dir))
table_import(session::AccumuloSession, tablename::AbstractString, import_dir::AbstractString) = importTable(client(session), handle(session), utf8(tablename), utf8(import_dir))

# take tables online/offline
table_offline(session::AccumuloSession, tablename::AbstractString; wait::Bool=true) = offlineTable(client(session), handle(session), utf8(tablename), wait)
table_online(session::AccumuloSession, tablename::AbstractString; wait::Bool=true) = onlineTable(client(session), handle(session), utf8(tablename), wait)

# get a list of all existing tables
tables(session::AccumuloSession) = listTables(client(session), handle(session))

#=
namespaces not supported yet
# displays a list of all existing namespaces
function namespaces()
end

# creates a new namespace
function createnamespace()
end

# deletes a namespace
function deletenamespace()
end

# renames a namespace
function renamenamespace()
end 
=#
