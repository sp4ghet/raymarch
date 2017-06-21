using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode, RequireComponent(typeof(Renderer))]
public class RayMarchingObject : MonoBehaviour {

	[SerializeField]
	private Material material_;
	private int scaleId_;

	void Awake() {
		GetComponent<Renderer>().material = material_;
		scaleId_ = Shader.PropertyToID("_Scale");
	}

	void Update() {
		material_.SetVector(scaleId_, transform.localScale);
	}
}