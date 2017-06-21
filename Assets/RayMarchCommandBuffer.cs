using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class RayMarchCommandBuffer : MonoBehaviour {

	Mesh quad_;
	Dictionary<Camera, CommandBuffer> cameras_ = new Dictionary<Camera, CommandBuffer>();

	[SerializeField]
	Material material = null;
	[SerializeField]
	CameraEvent pass = CameraEvent.BeforeGBuffer;

	Mesh GenerateQuad() {
		var mesh = new Mesh();
		mesh.vertices = new Vector3[4] {
			new Vector3(1.0f, 1.0f, 0f),
			new Vector3(-1.0f, 1.0f, 0f),
			new Vector3(-1.0f, -1.0f, 0f),
			new Vector3(1.0f, -1.0f, 0f)
		};
		mesh.triangles = new int[6] {
			0,1,2,
			2,3,0
		};
		return mesh;
	}

	void CleanUp() {
		foreach(var pair in cameras_) {
			var camera = pair.Key;
			var buffer = pair.Value;

			camera.RemoveCommandBuffer(pass, buffer);
		}
		cameras_.Clear();
	}

	private void OnEnable() {
		CleanUp();
	}

	private void OnDisable() {
		CleanUp();
	}

	private void OnWillRenderObject() {
		UpdateCommandBuffer();
	}

	void UpdateCommandBuffer() {
		var act = gameObject.activeInHierarchy && enabled;

		if (!act) {
			OnDisable();
			return;
		}

		var camera = Camera.current;
		if (camera == null) return;

		if (cameras_.ContainsKey(camera)) return;

		if (quad_ == null) quad_ = GenerateQuad();

		var buffer = new CommandBuffer();
		buffer.name = "RayMarching";
		buffer.DrawMesh(quad_, Matrix4x4.identity, material, 0, 0);
		camera.AddCommandBuffer(pass, buffer);
		cameras_.Add(camera, buffer);
	}
}
