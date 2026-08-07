import bpy
import os

WORKSPACE_DIR = r"c:\Users\User\Documents\THRESHOLD"
MII_MAKER_BLEND = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\Mii_Maker_for_4.1_v2.blend")

OUTPUT_BLEND = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\mixamo_character_aligned.blend")
OUTPUT_GLB = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\mixamo_ready_character.glb")
OUTPUT_OBJ = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\mixamo_ready_character.obj")

def main():
    if not os.path.exists(MII_MAKER_BLEND):
        print("Mii Maker blend file not found!")
        return

    print("Opening Mii_Maker_for_4.1_v2.blend...")
    bpy.ops.wm.open_mainfile(filepath=MII_MAKER_BLEND)
    
    body_src = bpy.data.objects.get("torso m weights") or bpy.data.objects.get("torso m")
    head_src = bpy.data.objects.get("head") or bpy.data.objects.get("head.001")
    
    if not body_src or not head_src:
        print("Could not find body or head in Mii Maker blend!")
        return

    # Duplicate body and head
    body_copy = body_src.copy()
    body_copy.data = body_src.data.copy()
    body_copy.name = "Body_Mesh"
    
    head_copy = head_src.copy()
    head_copy.data = head_src.data.copy()
    head_copy.name = "Head_Mesh"

    # Set world matrices matching Mii Maker exact positions
    body_copy.matrix_world = body_src.matrix_world.copy()
    head_copy.matrix_world = head_src.matrix_world.copy()

    # Clear parents
    body_copy.parent = None
    head_copy.parent = None

    # Remove any modifiers (like DataTransfer)
    for obj in (body_copy, head_copy):
        for mod in list(obj.modifiers):
            obj.modifiers.remove(mod)

    # Link duplicated Body_Mesh and Head_Mesh to scene collection
    main_col = bpy.context.scene.collection
    if body_copy.name not in main_col.objects:
        main_col.objects.link(body_copy)
    if head_copy.name not in main_col.objects:
        main_col.objects.link(head_copy)

    # Safely remove all other original objects from scene
    for obj in list(bpy.data.objects):
        if obj not in (body_copy, head_copy):
            for col in list(obj.users_collection):
                col.objects.unlink(obj)
            bpy.data.objects.remove(obj, do_unlink=True)

    # Create Blank Anchor Nodes (Empties) for Hair & Glasses anchoring later
    hair_anchor = bpy.data.objects.new("Hair_Anchor", None)
    hair_anchor.empty_display_type = 'PLAIN_AXES'
    hair_anchor.empty_display_size = 0.1
    hair_anchor.location = (0.0, 0.0, 0.15)
    hair_anchor.parent = head_copy
    main_col.objects.link(hair_anchor)

    glasses_anchor = bpy.data.objects.new("Glasses_Anchor", None)
    glasses_anchor.empty_display_type = 'PLAIN_AXES'
    glasses_anchor.empty_display_size = 0.1
    glasses_anchor.location = (0.0, -0.08, 0.0)
    glasses_anchor.parent = head_copy
    main_col.objects.link(glasses_anchor)

    # Save clean .blend file
    bpy.ops.wm.save_as_mainfile(filepath=OUTPUT_BLEND)
    print(f"Successfully saved Mii-Maker proportioned Blend file: {OUTPUT_BLEND}")

    # Select Body and Head for GLB/OBJ export
    body_copy.select_set(True)
    head_copy.select_set(True)
    bpy.context.view_layer.objects.active = body_copy
    
    bpy.ops.export_scene.gltf(filepath=OUTPUT_GLB, export_format='GLB')
    try:
        bpy.ops.wm.obj_export(filepath=OUTPUT_OBJ)
    except Exception as e:
        print("OBJ Export Notice:", e)

    print("Exported GLB & OBJ matching Mii Maker proportions!")

if __name__ == "__main__":
    main()
