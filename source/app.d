import std.stdio;
import std.getopt;
import mysql;
import mysql.protocol.sockets;

// TODO: make this avoid keywords and deal with any differences between table requirements and symbol requirements
string makeValidDSymbol(string s)
{
    return s;
}

int main(string[] args)
{
    string username;
    string password;
    string host = "127.0.0.1";
    string databasename;

    auto helpInformation = getopt(
        args,
        "host|h", "Host for connection. If not specified, localhost is used", &host,
        config.required,
        "user|u",  &username,
        config.required,
        "password|p",  &password,
        config.required,
        "database|d", &databasename);

    if(helpInformation.helpWanted)
    {
        defaultGetoptFormatter(stderr.lockingTextWriter,
            "Generate an appropriate set of database rows that can be used for serializing with the provided database tables.",
            helpInformation.options);
        return 1;
    }

    // connect to the database, and start extracting data
    import std.stdio;
    auto conn = new Connection(MySQLSocketType.phobos, host, username, password, databasename);
    scope(exit) conn.close();

    auto meta = MetaData(conn);
    foreach(t; meta.tables)
    {
        writefln("struct %s {", makeValidDSymbol(t));
        foreach(c; meta.columns(t))
        {
            import std.traits;
            /*static foreach(m; ["name", "extra", "type", "octetsMax", "charsMax", "numericPrecision", "key", "colType"])
                write(", ",  m, ": ", __traits(getMember, c, m));
            writeln();*/
            auto nullable = c.nullable ? "Nullable!" : "";
            switch(c.type)
            {
            case "int":
                if(c.colType == "int unsigned")
                    writefln("    %suint %s;", nullable, makeValidDSymbol(c.name));
                else
                    writefln("    %sint %s;", nullable, makeValidDSymbol(c.name));
                break;
            case "tinyint":
                if(c.colType == "tinyint unsigned")
                    writefln("    %subyte %s;", nullable, makeValidDSymbol(c.name));
                else if(c.colType == "tinyint(1)")
                    writefln("    %sbool %s;", nullable, makeValidDSymbol(c.name));
                else
                    writefln("    %sbyte %s;", nullable, makeValidDSymbol(c.name));
                break;
            case "smallint":
                if(c.colType == "smallint unsigned")
                    writefln("    %sushort %s;", nullable, makeValidDSymbol(c.name));
                else
                    writefln("    %sshort %s;", nullable, makeValidDSymbol(c.name));
                break;
            case "bigint":
                if(c.colType == "bigint unsigned")
                    writefln("    %sulong %s;", nullable, makeValidDSymbol(c.name));
                else
                    writefln("    %slong %s;", nullable, makeValidDSymbol(c.name));
                break;
            case "float":
                writefln("    %sfloat %s;", nullable, makeValidDSymbol(c.name));
                break;
            case "double":
                writefln("    %sdouble %s;", nullable, makeValidDSymbol(c.name));
                break;
            case "bit":
                if(c.colType == "bit")
                    writefln("    %sbool %s;", nullable, makeValidDSymbol(c.name));
                else
                    throw new Exception("unknown col type: " ~ c.colType);
                break;
            case "time":
                writefln("    %sTimeOfDay %s;", nullable, makeValidDSymbol(c.name));
                break;
            case "datetime":
            case "timestamp":
                writefln("    %sDateTime %s;", nullable, makeValidDSymbol(c.name));
                break;
            case "date":
                writefln("    %sDate %s;", nullable, makeValidDSymbol(c.name));
                break;
            case "char":
            case "varchar":
            case "text":
                writefln("    %sstring %s;", nullable, makeValidDSymbol(c.name));
                break;
            case "blob":
                writefln("    %subyte[] %s;", nullable, makeValidDSymbol(c.name));
                break;
            default:
                throw new Exception("Unknown type: " ~ c.type);
            }
        }
        writefln("}\n");
    }
    return 0;
}
