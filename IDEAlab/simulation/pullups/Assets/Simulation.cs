using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Simulation {

    public static float sine(float deg)
    {
        return Mathf.Sin(Mathf.Deg2Rad * deg);
    }

    public static float cosine(float deg)
    {
        return Mathf.Cos(Mathf.Deg2Rad * deg);
    }

    public static GameObject createBlock(Vector3 pos, Vector3 rot, Vector3 scale, int layer)
    {
        GameObject go = GameObject.CreatePrimitive(PrimitiveType.Cube);
        go.transform.position = pos;
        go.transform.localEulerAngles = rot;
        go.transform.localScale = scale;
        go.layer = layer;

        return go;
    }

    public static Rigidbody addRb(GameObject go, float mass)
    {
        Rigidbody rb = go.AddComponent<Rigidbody>();
        rb.mass = mass;
        rb.angularDrag = 0;

        return rb;
    }

    public static HingeJoint addJoint(GameObject go, Rigidbody connected, Vector3 anchor)
    {
        HingeJoint hj = go.AddComponent<HingeJoint>();
        hj.connectedBody = connected;
        hj.anchor = anchor;

        return hj;
    }
}
