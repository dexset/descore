/+
The MIT License (MIT)

    Copyright (c) <2013> <Oleg Butko (deviator), Anton Akzhigitov (Akzwar)>

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
+/

module desmath.graph.base;

class GraphException: Exception
{
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ )
    { super( msg, file, line ); }
}

template Graph(NIC, LIC)
{
    alias NIC NodeInfoCore;
    alias LIC LinkInfoCore;

    interface Link
    {
        @property 
        {
            ref LinkInfoCore info();
            ref const(LinkInfoCore) info() const;

            const(Node) nodeA() const;
            const(Node) nodeB() const;
            Node nodeA();
            Node nodeB();

            bool biDirection() const;
            void biDirection( bool );
        }

        void reverseDirection();
    }

    interface LinkPad
    {
        @property
        {
            const(LinkPad) other() const;
            LinkPad other();

            bool isOutput() const;
            void isOutput( bool );

            const(Node) self() const;
            Node self();

            const(Link) link() const;
            Link link();

            final
            {
                bool isInput() const { return other.isOutput; }

                const(Node) follow() const { return isOutput ? node : null; }
                Node follow() { return isOutput ? node : null; }

                const(Node) node() const { return other.self; }
                Node node() { return other.self; }

                ref const(LinkInfoCore) info() const { return link.info; }
                ref LinkInfoCore info() { return link.info; }
            }
        }
    }

    interface Node
    {
        @property
        {
            ref const(NodeInfoCore) info() const;
            ref NodeInfoCore info();

            const(LinkPad)[] link() const;
            LinkPad[] link();
        }
    }

    class SLink : Link
    {
    protected:
        SLinkPad[2] pads;
        LinkInfoCore lic;

        enum getOtherStr = 
            `
            if( pad is pads[0] ) return pads[1];
            else if( pad is pads[1] ) return pads[0];
            else throw new GraphException( "bad link pad call" );
            `;

        const(SLinkPad) getOther( in SLinkPad pad ) const { mixin( getOtherStr ); }
        SLinkPad getOther( in SLinkPad pad ) { mixin( getOtherStr ); }

    public:

        this( SNode nodeA, SNode nodeB, LinkInfoCore val, bool biDir=true )
        {
            lic = val;
            pads[0] = new SLinkPad( this, nodeA, true );
            pads[1] = new SLinkPad( this, nodeB, biDir );
        }

        @property 
        {
            ref LinkInfoCore info() { return lic; }
            ref const(LinkInfoCore) info() const { return lic; }

            const(Node) nodeA() const { return pads[0].self; }
            const(Node) nodeB() const { return pads[1].self; }

            Node nodeA() { return pads[0].self; }
            Node nodeB() { return pads[1].self; }

            bool biDirection() const { return pads[1].isOutput; }
            void biDirection( bool v ) { pads[1].isOutput = v; }
        }

        void reverseDirection()
        {
            auto buf = pads[0];
            pads[0] = pads[1];
            pads[1] = buf;
        }

        void destroy()
        {
            foreach( pad; pads ) 
                pad.destroyByLink();
        }
    }

    private class SLinkPad : LinkPad
    {
        SLink parent;
        SNode self_node;
        bool is_output;

        this( SLink L, SNode N, bool O )
        {
            parent = L;
            self_node = N;
            self_node.addLink( this );
            is_output = O;
        }

        ubyte destr = 0;

        void destroyByLink() 
        {
            if( destr == 0 ) 
            {
                destr = 1;
                if( self_node ) 
                    self_node.delLink( this );
                self_node = null;
            }
        }

        void destroyByNode() 
        {
            if( destr == 0 ) 
            {
                destr = 2;
                parent.destroy(); 
            }
        }

        final @property
        {
            const(LinkPad) other() const { return parent.getOther( this ); }
            LinkPad other() { return parent.getOther( this ); }

            bool isOutput() const { return is_output; }
            void isOutput( bool v ) { is_output = v; }

            const(Node) self() const { return self_node; }
            Node self() { return self_node; }

            const(Link) link() const { return parent; }
            Link link() { return parent; }
        }
    }

    class SNode : Node
    {
    private:
        NodeInfoCore nic;
        SLinkPad[] lplist;

        void addLink( SLinkPad[] list... ) 
        { lplist ~= list; }

        void delLink( SLinkPad[] list... )
        {
            SLinkPad[] alive;
            foreach( ln; lplist )
            {
                bool ok = true;
                foreach( l; list )
                    if( l is ln ) 
                    {
                        ok = false;
                        ln.destroyByNode();
                        break;
                    }
                if( ok ) alive ~= ln;
            }
            lplist = alive;
        }

    public:
        this( NodeInfoCore val ) { nic = val; }

        @property
        {
            ref const(NodeInfoCore) info() const { return nic; }
            ref NodeInfoCore info() { return nic; }

            const(LinkPad)[] link() const 
            { 
                const(LinkPad)[] ret;
                foreach( ln; lplist ) ret ~= ln;
                return ret; 
            }

            LinkPad[] link() 
            { 
                LinkPad[] ret;
                foreach( ln; lplist ) ret ~= ln;
                return ret; 
            }
        }

        void destroy()
        {
            foreach( ln; lplist )
                ln.destroyByNode();
        }
    }
}

unittest
{
    alias Graph!(string,float) GraphSF;
    alias GraphSF.SLink Link;
    alias GraphSF.SNode Node;

    auto apple = new Node( "apple" );
    auto nokia = new Node( "nokia" );
    auto htc = new Node( "htc" );

    htc.info = "htc inc";
    assert( htc.info == "htc inc" );

    auto ln1 = new Link( apple, nokia, 1.0f, false );
    auto ln2 = new Link( nokia, htc, 0.5f );

    assert( apple.link[0].info == 1.0 );
    assert( apple.link[0].node.link[1].node is htc );

    ln1.destroy();
    assert( apple.link.length == 0 );
    assert( nokia.link.length == 1 );
    assert( htc.link.length == 1 );
    assert( nokia.link[0].node is htc );

    htc.destroy();
    assert( nokia.link.length == 0 );
    assert( ln2.pads[0].destr );
    assert( ln2.pads[1].destr );
}

