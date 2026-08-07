import bpy
import os

WORKSPACE_DIR = r"c:\Users\User\Documents\THRESHOLD"
TARGET_BLEND = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\mixamo_character.blend")
OUTPUT_GLB = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\mixamo_ready_character.glb")
OUTPUT_OBJ = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\mixamo_ready_character.obj")

def main():
    if not os.path.exists(TARGET_BLEND):
        print(f"File not found: {TARGET_BLEND}")
        return

    print(f"Opening user blend file: {TARGET_BLEND}")
    bpy.ops.wm.open_mainfile(filepath=TARGET_BLEND)

    # 1. Find and remove any Armature objects and bones
    armatures_removed = 0
    for obj in list(bpy.data.objects):
        if obj.type == 'ARMATURE':
            bpy.data.objects.remove(obj, do_unlink=True)
            armatures_removed += 1

    print(f"Removed {armatures_removed} armature object(s).")

    # 2. Remove Armature modifiers and unparent from any removed armatures
    mesh_count = 0
    for obj in bpy.data.objects:
        if obj.type == 'MESH':
            mesh_count += 1
            # Unparent if parent was removed or was armature
            if obj.parent and obj.parent.type == 'ARMATURE':
                obj.parent = None
            # Clear armature modifiers
            for mod in list(obj.modifiers):
                if mod.type == 'ARMATURE':
                    obj.modifiers.remove(mod)

    print(f"Processed {mesh_count} mesh object(s). Scene is now MESH + EMPTIES only.")

    # 3. Save cleaned blend file
    bpy.ops.wm.save_as_mainfile(filepath=TARGET_BLEND)
    print(f"Saved cleaned blend file: {TARGET_BLEND}")

    # 4. Select all MESH objects for export
    bpy.ops.object.select_all(action='DESELECT')
    export_objs = [o for o in bpy.data.objects if o.type == 'MESH']
    for o in export_objs:
        o.select_set(True)

    if export_objs:
        bpy.context.view_layer.objects.active = export_objs[0]

    # 5. Export mesh-only GLB & OBJ for Mixamo
    bpy.ops.export_scene.gltf(filepath=OUTPUT_GLB, export_format='GLB')
    print(f"Exported clean GLB for Mixamo: {OUTPUT_GLB}")

    try:
        bpy.ops.wm.obj_export(filepath=OUTPUT_OBJ)
        print(f"Exported clean OBJ for Mixamo: {OUTPUT_OBJ}")
    except Exception as e:
        print("OBJ Export Notice:", e)

if __name__ == "__main__":
    main()
