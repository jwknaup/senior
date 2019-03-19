using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using System.IO;
using UnityEditor;

public class LegInverted
{
    public GameObject thighLa, thighLb, thighRa, thighRb;
    public GameObject calfL, calfR;
    public GameObject ground, top, bot;

    public Rigidbody thighLaBody, thighLbBody, thighRaBody, thighRbBody, calfLBody, calfRBody, topBody;

    public float start_height, drop_height, thigh_length, spring_length, global_thickness, global_width, calf_length, calf_angle, thigh_angle, foot_height, foot_length, vertical_spring, spring_transmission, spring_damper;
    public float spring_constant;
    public float top_mass, totalMass, segment_mass, density;
    public float lengthScaleFactor, massScaleFactor, forceScaleFactor, torqueScaleFactor;
    public float joint_spring, joint_damper, flex_damper, translational_drag, angular_drag;
    public float maxTorque, maxRpm, gear_ratio;

    public void createLeg(bool contact)
    {
        //******Transforms******

        thighLa = GameObject.CreatePrimitive(PrimitiveType.Cube);
        thighLa.transform.position = new Vector3(0, thigh_length * .75F * Mathf.Sin(Mathf.Deg2Rad * thigh_angle), -.25F * thigh_length * Mathf.Cos(Mathf.Deg2Rad * thigh_angle));
        thighLa.transform.localEulerAngles = new Vector3(-thigh_angle, 0, 0);
        thighLa.transform.localScale = new Vector3(global_width, global_thickness, 0.5f * thigh_length);
        thighLa.layer = 9;

        thighRa = GameObject.CreatePrimitive(PrimitiveType.Cube);
        thighRa.transform.position = new Vector3(0, thigh_length * .75F * Mathf.Sin(Mathf.Deg2Rad * thigh_angle), .25F * thigh_length * Mathf.Cos(Mathf.Deg2Rad * thigh_angle));
        thighRa.transform.localEulerAngles = new Vector3(thigh_angle, 0, 0);
        thighRa.transform.localScale = new Vector3(global_width, global_thickness, 0.5f * thigh_length);
        thighRa.layer = 9;

        thighLb = Simulation.createBlock(new Vector3(0, thigh_length * .25F * Simulation.sine(thigh_angle), -.75F * thigh_length * Simulation.cosine(thigh_angle)), new Vector3(-thigh_angle, 0, 0), new Vector3(global_width, global_thickness, 0.5f * thigh_length), 9);
        thighRb = Simulation.createBlock(new Vector3(0, thigh_length * .25F * Simulation.sine(thigh_angle), .75F * thigh_length * Simulation.cosine(thigh_angle)), new Vector3(thigh_angle, 0, 0), new Vector3(global_width, global_thickness, 0.5f * thigh_length), 9);

        calfL = GameObject.CreatePrimitive(PrimitiveType.Cube);
        calfL.transform.position = new Vector3(0, -.5F * calf_length * Simulation.sine(calf_angle), -.5F * calf_length * Simulation.cosine(calf_angle));
        calfL.transform.localEulerAngles = new Vector3(calf_angle, 0, 0);
        calfL.transform.localScale = new Vector3(global_width, global_thickness, calf_length);
        calfL.layer = 9;
        BoxCollider ms = calfL.GetComponent<BoxCollider>();
        ms.material = new PhysicMaterial();
        ms.material.dynamicFriction = 999;
        ms.material.staticFriction = 999;
        ms.material.bounciness = 0;

        calfR = GameObject.CreatePrimitive(PrimitiveType.Cube);
        calfR.transform.position = new Vector3(0, -.5F * calf_length * Simulation.sine(calf_angle), .5F * calf_length * Simulation.cosine(calf_angle));
        calfR.transform.localEulerAngles = new Vector3(-calf_angle, 0, 0);
        calfR.transform.localScale = new Vector3(global_width, global_thickness, calf_length);
        calfR.layer = 9;
        ms = calfR.GetComponent<BoxCollider>();
        ms.material = new PhysicMaterial();
        ms.material.dynamicFriction = 999;
        ms.material.staticFriction = 999;
        ms.material.bounciness = 0;

        top = Simulation.createBlock(new Vector3(0, thigh_length * Simulation.sine(thigh_angle), 0), new Vector3(0, 0, 0), new Vector3(global_width, spring_length, 2 * spring_length), 9);


        //*******Rigid Bodies*********

        thighLaBody = thighLa.AddComponent<Rigidbody>();
        thighLaBody.mass = .5F * segment_mass;
        thighLaBody.drag = translational_drag;
        thighLaBody.angularDrag = angular_drag;
        thighRaBody = thighRa.AddComponent<Rigidbody>();
        thighRaBody.mass = .5F * segment_mass;
        thighRaBody.drag = translational_drag;
        thighRaBody.angularDrag = angular_drag;
        thighLbBody = Simulation.addRb(thighLb, .5f * segment_mass);
        thighLbBody.drag = translational_drag;
        thighLbBody.angularDrag = angular_drag;
        thighRbBody = Simulation.addRb(thighRb, .5f * segment_mass);
        thighRbBody.drag = translational_drag;
        thighRbBody.angularDrag = angular_drag;
        calfLBody = calfL.AddComponent<Rigidbody>();
        calfLBody.mass = segment_mass;
        calfLBody.drag = translational_drag;
        calfLBody.angularDrag = angular_drag;
        calfLBody.collisionDetectionMode = CollisionDetectionMode.ContinuousDynamic;
        calfRBody = calfR.AddComponent<Rigidbody>();
        calfRBody.mass = segment_mass;
        calfRBody.drag = translational_drag;
        calfRBody.angularDrag = angular_drag;
        calfRBody.collisionDetectionMode = CollisionDetectionMode.ContinuousDynamic;

        //bot = GameObject.CreatePrimitive(PrimitiveType.Cube);
        topBody = Simulation.addRb(top, top_mass);
        topBody.drag = translational_drag;
        topBody.angularDrag = angular_drag;

        //*********Joints************

        HingeJoint hj = calfL.AddComponent<HingeJoint>();
        hj.connectedBody = thighLbBody;
        hj.anchor = new Vector3(0, 0, -.5F);
        hj.autoConfigureConnectedAnchor = true;
        hj.connectedAnchor = new Vector3(0, 0, -.5F);
        JointSpring js = hj.spring;
        js.spring = joint_spring;
        js.damper = joint_damper;
        js.targetPosition = 0;
        hj.spring = js;
        hj.useSpring = true;

        hj = calfR.AddComponent<HingeJoint>();
        hj.connectedBody = thighRbBody;
        hj.anchor = new Vector3(0, 0, .5F);
        hj.autoConfigureConnectedAnchor = true;
        hj.connectedAnchor = new Vector3(0, 0, .5F);
        js = hj.spring;
        js.spring = joint_spring;
        js.damper = joint_damper;
        js.targetPosition = 0;
        hj.spring = js;
        hj.useSpring = true;

        hj = calfL.AddComponent<HingeJoint>();
        hj.connectedBody = calfRBody;
        hj.anchor = new Vector3(0, 0, .5F);
        hj.autoConfigureConnectedAnchor = true;
        hj.connectedAnchor = new Vector3(0, 0, -.5F);
        js = hj.spring;
        /// TODO make sure this spring constant is right and below
        js.spring = joint_spring;
        js.damper = joint_damper;
        js.targetPosition = 0;
        hj.spring = js;
        hj.useSpring = true;

        hj = Simulation.addJoint(top, thighLaBody, new Vector3(0, 0, -.1f));
        /// TODO replace joint motor here and below with ful motor model
        JointMotor jm = hj.motor;
        jm.force = maxTorque;
        jm.targetVelocity = maxRpm * 360 / 60 * -1;
        hj.motor = jm;
        hj.useMotor = true;
        JointLimits jl = hj.limits;
        jl.min = -85;
        jl.max = 85;
        hj.limits = jl;
        hj.useLimits = true;

        hj = Simulation.addJoint(top, thighRaBody, new Vector3(0, 0, .1f));
        jm = hj.motor;
        jm.force = maxTorque;
        jm.targetVelocity = maxRpm * 360 / 60 * 1;
        hj.motor = jm;
        hj.useMotor = true;
        jl = hj.limits;
        jl.min = -85;
        jl.max = 85;
        hj.limits = jl;
        hj.useLimits = true;

        hj = Simulation.addJoint(thighLa, thighLbBody, new Vector3(0, 0, -.5f));
        hj.autoConfigureConnectedAnchor = false;
        hj.connectedAnchor = new Vector3(0, 0, 0.5f);
        js = hj.spring;
        /// TODO make sure this spring constant is right and below
        js.spring = (float)spring_constant;
        js.targetPosition = 0;
        js.damper = flex_damper;
        hj.spring = js;
        hj.useSpring = true;

        hj = Simulation.addJoint(thighRa, thighRbBody, new Vector3(0, 0, .5f));
        js = hj.spring;
        js.spring = (float)spring_constant;
        js.targetPosition = 0;
        js.damper = flex_damper;
        hj.spring = js;
        hj.useSpring = true;

        if (!contact)
        {
            hj = Simulation.addJoint(ground, calfLBody, new Vector3(0, 0, 0));
            ground.GetComponent<Rigidbody>().isKinematic = true;
        }

        thighLaBody.maxAngularVelocity = 10000;
        thighRaBody.maxAngularVelocity = 10000;
        thighLbBody.maxAngularVelocity = 10000;
        thighRbBody.maxAngularVelocity = 10000;
        calfLBody.maxAngularVelocity = 10000;
        calfRBody.maxAngularVelocity = 10000;
    }

    public void createGround()
    {
        ground = GameObject.CreatePrimitive(PrimitiveType.Plane);
        ground.transform.position = new Vector3(0, -drop_height - calf_length * Simulation.sine(calf_angle), 0);
        ground.transform.localScale = new Vector3(10F, 1F, 10F);

        MeshRenderer rend = ground.GetComponent<MeshRenderer>();
        rend.material.color = Color.black;

        MeshCollider ms = ground.GetComponent<MeshCollider>();
        ms.material = new PhysicMaterial();
        ms.material.dynamicFriction = 999;
        ms.material.staticFriction = 999;
        ms.material.bounciness = 0;
    }

    public void setDimensions(float length, float width, float thickness, float startAngle)
    {
        thigh_length = length*lengthScaleFactor;
        calf_length = thigh_length;
        global_width = width*lengthScaleFactor;
        global_thickness = thickness*lengthScaleFactor;

        drop_height = .001F*lengthScaleFactor;
        thigh_angle = startAngle;
        calf_angle = Mathf.Acos(thigh_length * Simulation.cosine(thigh_angle) / calf_length) * Mathf.Rad2Deg;

        spring_length = 0.01F*lengthScaleFactor;

    }

    public void setPhysConstants(float lsf, float msf, float gravityDirection)
    {
        lengthScaleFactor = lsf;
        massScaleFactor = msf;
        forceScaleFactor = massScaleFactor * lengthScaleFactor;
        torqueScaleFactor = forceScaleFactor * lengthScaleFactor;

        Time.fixedDeltaTime = 0.001f;
        Time.maximumDeltaTime = 6.0f;
        Time.captureFramerate = (int)(1 / Time.fixedDeltaTime);
        Physics.defaultSolverIterations = 60;
        Physics.gravity = new Vector3(0, 9.81f * lengthScaleFactor * gravityDirection, 0);
    }

    public void setSpringConstants(float rigidSpring, float rigidDamper, float jointSpring, float jointDamper)
    {
        spring_constant = rigidSpring;
        flex_damper = rigidDamper;
        joint_spring = jointSpring;
        joint_damper = jointDamper;
    }
    public void setDragConstants(float drag, float angularDrag)
    {
        translational_drag = drag;
        angular_drag = angularDrag;
    }

    public void setMasses(float topMass, float fiberglassDensity)
    {
        segment_mass = fiberglassDensity * massScaleFactor * thigh_length / lengthScaleFactor * global_thickness/lengthScaleFactor * global_width/lengthScaleFactor;//0.095f
        top_mass = topMass*massScaleFactor;// 0.72f;
    }

    public void setMotorConstants(float gearRatio, int direction)
    {
        gear_ratio = gearRatio;
        maxTorque = 0.1554f / 75.0f * gear_ratio * torqueScaleFactor;
        maxRpm = 400.0f * 75.0f / gear_ratio;
        if(gearRatio == 50)
        {
            maxTorque = .066f;
            maxRpm = 650;
        } else if(gearRatio == 75)
        {
            maxTorque = .098f;
            maxRpm = 450;
        } else if(gearRatio == 100)
        {
            maxTorque = .13f;
            maxRpm = 330;
        } else if(gearRatio == 150)
        {
            maxTorque = 0.18f;
            maxRpm = 220;
        } else if(gearRatio == 210)
        {
            maxTorque = 0.25f;
            maxRpm = 160;
        } else if(gearRatio == 250)
        {
            maxTorque = 0.30f;
            maxRpm = 130;
        } else if(gearRatio == 298)
        {
            maxTorque = 0.33f;
            maxRpm = 110;
        } else if(gearRatio == 1000)
        {
            maxTorque = 1.0f;
            maxRpm = 35;
        }

        maxRpm *= direction;
    }

}