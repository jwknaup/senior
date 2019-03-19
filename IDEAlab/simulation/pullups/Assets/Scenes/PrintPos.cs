using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PrintPos : MonoBehaviour {

    Rigidbody rb;

	// Use this for initialization
	void Start () {
        rb = GetComponent<Rigidbody>();
        Physics.gravity = new Vector3(0, 0, 0);
	}
	
	// Update is called once per frame
	void Update () {
        print(rb.velocity.y);
	}
}
