module desutil.socket;

public import std.socket;
import std.socketstream;

import desutil.pdata;

void log(string file=__FILE__, size_t line=__LINE__, Args...)( Args args )
{ 
    std.stdio.stderr.writef( "%s:%d ", file, line );
    std.stdio.stderr.writeln( args );
}

class SocketException: Exception
{ 
    @safe pure nothrow this( string msg, string file=__FILE__, int line=__LINE__ ) 
    { super( msg, file, line ); } 
}

interface DSocket
{
protected:
    alias ptrdiff_t delegate( const (void)[], size_t bs ) sendFunc;
    final void formSend( sendFunc func, in void[] data, int bs )
    {
        func( [bs], int.sizeof ); 
        int data_length = cast(int)data.length;
        func( [data_length], int.sizeof );

        void[] raw_data = data.dup;
        raw_data.length += bs - raw_data.length % bs;
        auto block_count = raw_data.length / bs;
        foreach( i; 0 .. block_count )
            func( raw_data[i*bs .. (i+1)*bs], bs );
    }

    alias ptrdiff_t delegate( void[] ) receiveFunc;
    final void[] formReceive( receiveFunc func )
    {
        int bs = -1;
        int full_size = -1;
        int data_size = -1;

        void[] raw_data;

        while( full_size != 0 )
        {
            void[] buffer;

            buffer.length = bs == -1 || full_size == -1 ? int.sizeof : bs;

            auto receive = func( buffer );
            if( receive == 0 )
                return [];

            if( full_size == -1 )
            {
                auto val = (cast(int[])(buffer))[0];
                if( bs == -1 )
                    bs = val;
                else
                {
                    data_size = val;
                    full_size = data_size + bs - data_size % bs;
                }
                continue;
            }

            raw_data ~= buffer;
            full_size -= bs;
        }
        return raw_data[ 0 .. data_size ].dup;
    }
}

class SListener : DSocket
{
private:
    Socket server;
    Socket client;
    alias void[] delegate( void[] ) callback;
    callback cb;

    void checkClient()
    {
        if( client is null )
        {
            version(socketlog) log( "client is null" );
            auto set = new SocketSet;
            set.add( server );
            if( Socket.select(set,null,null,dur!"msecs"(500) ) > 0 && set.isSet(server) )
            {
                version(socketlog) log( "locking" );
                server.blocking(true);
                client = server.accept();
                server.blocking(false);
            }
        }
    }
    int block_size = 16;
public:
    this( Address addr )
    {
        server = new TcpSocket();
        server.setOption( SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true );
        server.setOption( SocketOptionLevel.SOCKET, SocketOption.RCVTIMEO, dur!"usecs"(0) );
        server.bind( addr );
        server.listen(10);
        client = null;
    }

    this( ushort port ){ this( new InternetAddress( port ) ); }

    void setReceiveCB( callback _cb ){ cb = _cb; }

    void step()
    {
        version(socketlog) log("step");
        checkClient();

        if( client is null )
            return;
        version(socketlog) log("   client not null");


        auto set = new SocketSet;
        set.add( client );
        if( Socket.select(set,null,null,dur!"msecs"(0) ) <= 0 || !set.isSet(client) ) return;

        auto data = formReceive( &client.receive );
        if( data.length == 0 )
        {
            client = null;
            return;
        }
        version(socketlog) log("   data recived");
        if( cb !is null )
        {
            auto send_data = cb( data );
            if( send_data.length != 0 )
                formSend( (const(void)[] dd, size_t block_size){return client.send(dd);}, send_data, block_size );
        }
    }
}

class SSender : DSocket
{
private:
    Socket sender;
    int bs = 128;

    alias void delegate( void[] ) callback;
    callback cb;
    Address address;
    SocketStream ss;
public:
    this( Address addr )
    {
        sender = new TcpSocket();
        //sender.setOption( SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, true );
        address = addr;
        sender.connect( address );
        ss = new SocketStream( sender );
        sender.blocking(false);
    }
    void setReceiveCB( callback _cb ){ cb = _cb; }

    this( ushort port ) { this( new InternetAddress(port) ); }

    void step()
    {
        auto data = formReceive(( void[] data ) { return sender.receiveFrom(data, address); });
        if( cb !is null )
            cb( data );
    }

    void send( in ubyte[] data )
    {
        formSend( (const (void)[] dd, size_t block_size ){ return cast(ptrdiff_t)(ss.writeBlock( cast(void*)dd.ptr, block_size )); }, data, bs );
    }
}

unittest
{
    import std.random;
    SListener ll = new SListener( 4040 );
    SSender ss = new SSender( 4040 );
    ubyte[] data;
    data.length = 100;
    foreach( ref d; data )
        d = cast(ubyte)uniform( 100, 255 );
    ubyte[] rdata;
    rdata.length = 100;

    auto cb = ( void[] data )
    {
        void[] res;
        rdata = cast(ubyte[])data.dup;
        return res;
    };
    ll.setReceiveCB( cb );
    ss.send( data );
    ll.step();
    assert( data == rdata );
}
