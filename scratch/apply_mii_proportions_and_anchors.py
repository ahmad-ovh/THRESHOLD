import bpy
import os
import mathutils

WORKSPACE_DIR = r"c:\Users\User\Documents\THRESHOLD"
MII_MAKER_BLEND = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\Mii_Maker_for_4.1_v2.blend")

OUTPUT_BLEND = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\mixamo_character.blend")
OUTPUT_GLB = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\mixamo_ready_character.glb")
OUTPUT_OBJ = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\mixamo_ready_character.obj")

def main():
    if not os.path.exists(MII_MAKER_BLEND):
        print(f"Reference blend not found: {MII_MAKER_BLEND}")
        return

    print("Loading Mii_Maker_for_4.1_v2.blend reference...")
    bpy.ops.wm.open_mainfile(filepath=MII_MAKER_BLEND)

    # 1. Locate Body and Head in reference file
    body_src = bpy.data.objects.get("torso m weights") or bpy.data.objects.get("torso m")
    head_src = bpy.data.objects.get("head") or bpy.data.objects.get("head.001")

    if not body_src or not head_src:
        print("Error: Body or Head mesh not found in reference blend!")
        return

    # Duplicate meshes to isolate them cleanly
    body_mesh = body_src.copy()
    body_mesh.data = body_src.data.copy()
    body_mesh.name = "Body_Mesh"

    head_mesh = head_src.copy()
    head_mesh.data = head_src.data.copy()
    head_mesh.name = "Head_Mesh"

    # Match exact world transforms from Mii Maker reference
    body_mesh.matrix_world = body_src.matrix_world.copy()
    head_mesh.matrix_world = head_src.matrix_world.copy()

    # Clear parents keeping world transform
    body_mesh.parent = None
    head_mesh.parent = None

    # Remove modifiers
    for obj in (body_mesh, head_mesh):
        for mod in list(obj.modifiers):
            obj.modifiers.remove(mod)

    # Clear reference scene objects
    scene = bpy.context.scene
    main_col = scene.collection
    
    for obj in list(bpy.data.objects):
        if obj not in (body_mesh, head_mesh):
            for col in list(obj.users_collection):
                col.objects.unlink(obj)
            bpy.data.objects.remove(obj, do_unlink=True)

    main_col.objects.link(body_mesh)
    main_col.objects.link(head_mesh)

    # 2. Add Empty Anchor Nodes for Hair and Glasses parented to Head_Mesh
    hair_anchor = bpy.data.objects.new("Hair_Anchor", None)
    hair_anchor.empty_display_type = 'PLAIN_AXES'
    hair_anchor.empty_display_size = 0.1
    # Placed relative to Head_Mesh center (Z +0.15 for hair crown)
    hair_anchor.location = (0.0, 0.0, 0.15)
    hair_anchor.parent = head_mesh
    main_col.objects.link(hair_anchor)

    glasses_anchor = bpy.data.objects.new("Glasses_Anchor", None)
    glasses_anchor.empty_display_type = 'PLAIN_AXES'
    glasses_anchor.empty_display_size = 0.1
    # Placed relative to Head_Mesh center (Y -0.08 for eyes/glasses bridge)
    glasses_anchor.location = (0.0, -0.08, 0.0)
    glasses_anchor.parent = head_mesh
    main_col.objects.link(glasses_anchor)

    # 3. Save clean Blender file
    bpy.ops.wm.save_as_mainfile(filepath=OUTPUT_BLEND)
    print(f"Saved Mixamo Blender file with Mii proportions: {OUTPUT_BLEND}")

    # 4. Export GLB and OBJ
    bpy.ops.object.select_all(action='DESELECT')
    body_mesh.select_set(True)
    head_mesh.select_set(True)
    bpy.context.view_layer.objects.active = body_mesh

    bpy.ops.export_scene.gltf(filepath=OUTPUT_GLB, export_format='GLB')
    try:
        bpy.ops.wm.obj_export(filepath=OUTPUT_OBJ)
        print(f"Exported Mixamo OBJ: {OUTPUT_OBJ}")
    except Exception as e:
        print(f"OBJ Export notice: {e}")

    print(f"Exported Mixamo GLB: {OUTPUT_GLB}")

if __name__ == "__main__":
    main()
