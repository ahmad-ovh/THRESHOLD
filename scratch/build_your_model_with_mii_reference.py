import bpy
import os
import mathutils

WORKSPACE_DIR = r"c:\Users\User\Documents\THRESHOLD"

# YOUR ACTUAL 3D MODELS (NOT copied from Mii Maker!)
BODY_GLTF = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\body\body_torso_m.gltf")
HEAD_GLTF = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\heads\head_head_001.gltf")

OUTPUT_BLEND = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\mixamo_character.blend")
OUTPUT_GLB = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\mixamo_ready_character.glb")
OUTPUT_OBJ = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\mixamo_ready_character.obj")

def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def import_gltf_model(filepath, name):
    if not os.path.exists(filepath):
        print(f"File not found: {filepath}")
        return None
        
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=filepath)
    after = set(bpy.data.objects)
    new_objs = list(after - before)
    
    mesh_objs = [o for o in new_objs if o.type == 'MESH']
    if not mesh_objs:
        return None
        
    for o in mesh_objs:
        bpy.context.view_layer.objects.active = o
        o.select_set(True)
        bpy.ops.object.parent_clear(type='CLEAR_KEEP_TRANSFORM')
        
    for o in new_objs:
        if o.type != 'MESH':
            bpy.data.objects.remove(o, do_unlink=True)
            
    if len(mesh_objs) > 1:
        bpy.ops.object.select_all(action='DESELECT')
        for o in mesh_objs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = mesh_objs[0]
        bpy.ops.object.join()
        main_obj = bpy.context.active_object
    else:
        main_obj = mesh_objs[0]
        
    main_obj.name = name
    return main_obj

def main():
    clear_scene()
    
    # 1. Import YOUR Body Model (body_torso_m.gltf)
    body = import_gltf_model(BODY_GLTF, "Body_Mesh")
    if body:
        # Align Body origin to feet at Z=0
        bbox = [body.matrix_world @ mathutils.Vector(c) for c in body.bound_box]
        min_z = min(v.z for v in bbox)
        min_x, max_x = min(v.x for v in bbox), max(v.x for v in bbox)
        min_y, max_y = min(v.y for v in bbox), max(v.y for v in bbox)
        
        body.location = (-(min_x + max_x) / 2.0, -(min_y + max_y) / 2.0, -min_z)
        bpy.context.view_layer.objects.active = body
        body.select_set(True)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    # 2. Import YOUR Head Model (head_head_001.gltf)
    head = import_gltf_model(HEAD_GLTF, "Head_Mesh")
    if head:
        # Set origin of head to bounds center
        bpy.context.view_layer.objects.active = head
        head.select_set(True)
        bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
        
        # Position Head at Z=1.22 BU sitting right on top of torso neck (Z=0.95 BU)
        # using the exact Blender Unit numeric reference from Mii Maker
        head.location = (0.0, 0.0, 1.22)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    # 3. Add Blank Anchor Empties based on Mii Maker numeric positions
    col = bpy.context.scene.collection

    hair_anchor = bpy.data.objects.new("Hair_Anchor", None)
    hair_anchor.empty_display_type = 'PLAIN_AXES'
    hair_anchor.empty_display_size = 0.1
    hair_anchor.location = (0.0, 0.0, 1.47)  # Top of head crown in Blender Units
    hair_anchor.parent = head
    col.objects.link(hair_anchor)

    glasses_anchor = bpy.data.objects.new("Glasses_Anchor", None)
    glasses_anchor.empty_display_type = 'PLAIN_AXES'
    glasses_anchor.empty_display_size = 0.1
    glasses_anchor.location = (0.0, -0.15, 1.22)  # Front of face eyes in Blender Units
    glasses_anchor.parent = head
    col.objects.link(glasses_anchor)

    # 4. Save clean .blend file
    bpy.ops.object.select_all(action='DESELECT')
    bpy.ops.wm.save_as_mainfile(filepath=OUTPUT_BLEND)
    print(f"Saved clean Blend file using YOUR 3D models: {OUTPUT_BLEND}")

    # 5. Export GLB & OBJ for Mixamo
    if body and head:
        body.select_set(True)
        head.select_set(True)
        bpy.context.view_layer.objects.active = body
        
        bpy.ops.export_scene.gltf(filepath=OUTPUT_GLB, export_format='GLB')
        try:
            bpy.ops.wm.obj_export(filepath=OUTPUT_OBJ)
            print(f"Exported Mixamo OBJ: {OUTPUT_OBJ}")
        except Exception as e:
            print("OBJ Export:", e)
            
        print(f"Exported Mixamo GLB: {OUTPUT_GLB}")

if __name__ == "__main__":
    main()
