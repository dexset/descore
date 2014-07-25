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

module desphys.state;

public import desmath.linear.vector;
public import desmath.basic.traits;

struct MPoint
{ 
    dvec3 pos, vel;
    mixin( BasicMathOp!"pos vel" );

    auto rpart(T,string AS)( in vec!(3,T,AS) acc ) const
        if( is( T : double ) )
    { return MPoint( vel, dvec3(acc) ); }
}

struct MRotation
{
    /++ кватернион поворота из связанной СК в глобальную +/
    dquat q = quat( 0,0,0,1 );
    dvec3 omega;
    mixin( BasicMathOp!"q omega" );

    auto rpart(T,string AS)( in vec!(3,T,AS) j ) const
        if( is( T : double ) )
    { return MRotation( dquat(omega,0) * q * 0.5, j ); }
}

struct MObject
{
    MPoint pnt;
    MRotation rot;

    mixin( BasicMathOp!"pnt rot" );

    auto rpart( in dvec3 acc, in dvec3 j ) const
    { return MObject( pnt.rpart( acc ), rot.rpart( j ) ); }
}
