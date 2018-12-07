using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ApplyForce : MonoBehaviour {

    Rigidbody rb;

	// Use this for initialization
	void Start () {
        rb = GetComponent<Rigidbody>();
	}
	
	// Update is called once per frame
	void Update () {
        float rot = rb.rotation.eulerAngles.y;
        print(rot);
	}

    private void FixedUpdate()
    {
        rb.AddTorque(new Vector3(0,1.0f*3.14159f/180f,0));
    }
}
