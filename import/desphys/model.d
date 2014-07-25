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

module desphys.model;

public import desmath.linear.vector;

void log(string mod=__MODULE__, size_t line=__LINE__, T)(T t)
{
    import std.stdio;
    import std.string;
    stderr.writeln( "%s:%d %s", mod, line, t );
}

void log(string mod=__MODULE__, size_t line=__LINE__, T...)( string fmt, T args )
{
    import std.stdio;
    import std.string;
    stderr.writefln( "%s:%d %s", mod, line, format(fmt, args) );
}

struct Force { dvec3 val, r; }

struct ModelInfo
{
    dvec3 vel, acc;
    dquat orient=dquat(0,0,0,1);
    dvec3 rot;
    double rho=1;
}

struct PointInfo
{
    dvec3 vel, acc;
    dquat orient=dquat(0,0,0,1);
    dvec3 rot, rot_center;
    double rho=1;

    pure this( in dvec3 v, in dvec3 a, 
            in dquat or, in dvec3 rr, 
            in dvec3 rc, double rh=1 )
    {
        vel = v; acc = a;
        orient = or;
        rot = rr; rot_center = rc;
        rho = rh;
    }

    pure this( in ModelInfo mi, in dvec3 rc )
    {
        vel = mi.vel;
        acc = mi.acc;
        orient = mi.orient;
        rot = mi.rot;
        rot_center = rc;
        rho = mi.rho;
    }
}

/++ характеризующая точка +/
class DescriptionPoint
{
    /++ положение в связанной СК +/
    dvec3 pos;

    double mass;

    pure this( in dvec3 p, double rm=1 ) { pos = p; mass = rm; }

    /++ вычисление линейной скорости точки +/
    dvec3 selfVel( in PointInfo pinfo ) const
    { return pinfo.vel + pinfo.rot * ( pos - pinfo.rot_center ); }

    const 
    {
        /++ возвращает силы, приложенные в этой точке 
            (например это может быть двигатель),
            так же подъёмную силу и силу споротивления воздуха,
            плечо относительно положения самой точки
                потом суммируются с положением самой точки +/
        Force[] forces( in PointInfo pinfo ) { return []; }
        /++ возвращает моменты сил +/
        dvec3[] torques( in PointInfo pinfo ) { return []; }
    }
}

unittest
{
    auto dp = new DescriptionPoint( dvec3(0,10,0), 1 );
    auto pi = PointInfo( dvec3(10, 0, 0), dvec3(0,0,0), dquat(0,0,0,1), dvec3(0,0,1), dvec3(0,0,0) );
    assert( pi.vel == dvec3(10,0,0) );
    assert( pi.rot == dvec3(0,0,1) );
    assert( pi.rot_center == dvec3(0,0,0) );
    assert( dp.selfVel( pi ) == dvec3(0,0,0) );
}

class PhysicModel
{
    const
    {
        abstract @property
        {
            const(DescriptionPoint)[] list();
            double mass();
        }

        /++ вычисляет центр масс объекта и осевые моменты инерции +/
        @property dvec3[2] inertia()
        {
            dvec3 cm, j;
            double sm=0;

            foreach( pnt; list )
            {
                sm += pnt.mass;
                cm += pnt.pos * pnt.mass;
            }
            cm /= sm;

            foreach( pnt; list )
            {
                auto dst = cm - pnt.pos;
                j += dvec3( dst.yz.len2, 
                            dst.xz.len2, 
                            dst.xy.len2 ) * (pnt.mass / sm * mass);
            }

            return [cm,j];
        }

        /++ вычисляет и суммирует силы и моменты от характеризующих точек,
            на выходе даёт линейное и угловое ускорение +/
        dvec3[2] calc( in ModelInfo mi )
        {
            Force[] forces;
            dvec3[] torques;
            dvec3 sforce, storque;

            auto momentum = inertia;

            auto cm = momentum[0];
            auto J = momentum[1];

            auto pi = PointInfo( mi, cm );

            foreach( pnt; list )
            {
                foreach( f; pnt.forces( pi ) )
                    forces ~= Force( f.val, f.r + pnt.pos );
                torques ~= pnt.torques( pi );
            }

            foreach( f; forces )
            {
                auto dst = cm - f.r;
                if( dst.len2 != 0 )
                    storque += f.val * dst;
                sforce += f.val;
            }

            foreach( t; torques ) storque += t;

            auto acc = sforce / mass; 
            auto j = dvec3(0,0,0);
            auto stl = storque.len;

            if( stl != 0 )
            {
                auto ut = storque / stl;
                auto Is = ut.x ^^ 2 * J.x +
                          ut.y ^^ 2 * J.y +
                          ut.z ^^ 2 * J.z;
                j = storque / (Is + 0.0001);
            }

            return [ acc, j ];
        }
    }
}

version(unittest)
{
    private
    {
        class TestModel: PhysicModel
        {
            DescriptionPoint[] ll;
            override const @property
            {
                const(DescriptionPoint)[] list() { return ll; }
                double mass() 
                { 
                    double sm=0;
                    foreach( p; list )
                        sm += p.mass;
                    return sm;
                }
            }
        }

        class TestDP: DescriptionPoint
        {
            dvec3 ff;
            this( in dvec3 p, double rm, in dvec3 f )
            {
                super( p, rm );
                ff = f;
            }
            override Force[] forces( in PointInfo pinfo ) const 
            { return [ Force(ff) ]; }
        }
    }
}

unittest
{
    auto tm = new TestModel;
    tm.ll = [
        new DescriptionPoint( dvec3(1,0,0), 2 ),
        new DescriptionPoint( dvec3(-2,0,0), 1 )
    ];

    auto inert = tm.inertia();
    auto cm = inert[0];
    auto j = inert[1];
    assert( cm == dvec3(0,0,0) );
    assert( j.x == 0 );
    assert( j.y == j.z );

    ModelInfo mi;
    assert( tm.calc(mi) == [ dvec3(0,0,0), dvec3(0,0,0) ] );

    tm.ll ~= new TestDP( dvec3(0,0,0), 1, dvec3(0,0,1) );
    assert( tm.inertia() == [ cm, j ] );
    assert( tm.calc(mi) == [ dvec3(0,0,0.25), dvec3(0,0,0) ] );
    tm.ll ~= new TestDP( dvec3(2,0,0), 1, dvec3(0,0,1) );
    inert = tm.calc(mi);
    assert( inert[0] == dvec3(0,0,0.4) );
    assert( inert[1].x == 0 );
    assert( inert[1].y < 0 );
    assert( inert[1].z == 0 );
    tm.ll ~= new TestDP( dvec3(2,2,0), 5, dvec3(0,1,0) );
    inert = tm.calc(mi);
    assert( inert[0] == dvec3(0,.1,.2) );
    assert( inert[1].x < 0 );
    assert( inert[1].y > 0 );
    assert( inert[1].z > 0 );
}
