#!/usr/bin/env python3

import sys
import traceback

try:
    print("Testing PQC service import...")
    from routes.pqc_service import router as pqc_router
    print(f"✅ PQC router imported successfully")
    print(f"   Prefix: {pqc_router.prefix}")
    print(f"   Tags: {pqc_router.tags}")
    
    print("\nTesting FastAPI app creation...")
    from fastapi import FastAPI
    app = FastAPI()
    
    print("Adding PQC router to app...")
    app.include_router(pqc_router)
    print("✅ PQC router added to app")
    
    print("\nChecking registered routes...")
    for route in app.routes:
        if hasattr(route, 'path'):
            print(f"   {route.path}")
    
    print("\n✅ All tests passed!")
    
except Exception as e:
    print(f"❌ Error: {e}")
    traceback.print_exc()
    sys.exit(1)
