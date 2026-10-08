"""Idempotent registration of shared-package core and isolated PR UI test targets.
Preserves all existing owner signing/build settings; never generates credentials.
"""
import hashlib, plistlib, json
from pathlib import Path

def ident(s): return hashlib.sha1(('veil-tests:'+s).encode()).hexdigest()[:24].upper()
p=Path('PhotoVeil.xcodeproj/project.pbxproj'); d=plistlib.loads(p.read_bytes()); o=d['objects']
project=next(v for v in o.values() if v.get('isa')=='PBXProject'); root=o[project['mainGroup']]
products=o[project['productRefGroup']]
package=ident('package'); o[package]={'isa':'XCLocalSwiftPackageReference','relativePath':'.'}
project.setdefault('packageReferences',[])
if package not in project['packageReferences']:project['packageReferences'].append(package)

def file(path):
 existing=next((k for k,v in o.items() if v.get('isa')=='PBXFileReference' and v.get('path')==path),None)
 if existing:return existing
 k=ident(path);o[k]={'isa':'PBXFileReference','path':path,'sourceTree':'SOURCE_ROOT','lastKnownFileType':'sourcecode.swift' if path.endswith('.swift') else 'image.jpeg'}
 root['children'].append(k);return k

def target(name,files,ui=False,resources=()):
 tid=ident(name); phases=[]
 for kind, paths in [('PBXSourcesBuildPhase',files),('PBXFrameworksBuildPhase',[]),('PBXResourcesBuildPhase',resources)]:
  key=ident(name+kind);entries=[]
  for path in paths:
   ref=file(path); b=ident(name+path);o[b]={'isa':'PBXBuildFile','fileRef':ref};entries.append(b)
  o[key]={'isa':kind,'buildActionMask':'2147483647','files':entries,'runOnlyForDeploymentPostprocessing':'0'};phases.append(key)
 configurations=[]
 for cfg in ['Debug','Release']:
  k=ident(name+cfg);settings={'PRODUCT_BUNDLE_IDENTIFIER':'com.maksym1503.veil.'+name,'PRODUCT_NAME':'$(TARGET_NAME)','SWIFT_VERSION':'5.0','SDKROOT':'iphoneos','IPHONEOS_DEPLOYMENT_TARGET':'17.0','SUPPORTED_PLATFORMS':'iphoneos iphonesimulator','TARGETED_DEVICE_FAMILY':'1','GENERATE_INFOPLIST_FILE':'YES','CODE_SIGN_STYLE':'Automatic','SWIFT_OPTIMIZATION_LEVEL':'-Onone' if cfg=='Debug' else '-O','LD_RUNPATH_SEARCH_PATHS':'$(inherited) @executable_path/Frameworks @loader_path/Frameworks'}
  if ui:settings['TEST_TARGET_NAME']='PhotoVeil'
  o[k]={'isa':'XCBuildConfiguration','name':cfg,'buildSettings':settings};configurations.append(k)
 cl=ident(name+'configs');o[cl]={'isa':'XCConfigurationList','buildConfigurations':configurations,'defaultConfigurationName':'Release','defaultConfigurationIsVisible':'0'}
 prod=ident(name+'product');o[prod]={'isa':'PBXFileReference','explicitFileType':'wrapper.cfbundle','path':name+'.xctest','sourceTree':'BUILT_PRODUCTS_DIR'}
 if prod not in products['children']:products['children'].append(prod)
 deps=[];packageProducts=[]
 if ui:
  dep=ident(name+'dependency');o[dep]={'isa':'PBXTargetDependency','target':'4D12E90DD8AA33456686B704'};deps=[dep]
 else:
  product=ident(name+'ImageGeometry');o[product]={'isa':'XCSwiftPackageProductDependency','package':package,'productName':'ImageGeometry'};packageProducts=[product]
  link=ident(name+'link');o[link]={'isa':'PBXBuildFile','productRef':product};o[phases[1]]['files'].append(link)
 o[tid]={'isa':'PBXNativeTarget','name':name,'productName':name,'productReference':prod,'productType':'com.apple.product-type.bundle.ui-testing' if ui else 'com.apple.product-type.bundle.unit-test','buildConfigurationList':cl,'buildPhases':phases,'buildRules':[],'dependencies':deps,'packageProductDependencies':packageProducts}
 if tid not in project['targets']:project['targets'].append(tid)
 return tid
core=target('PhotoVeilCoreTests',[str(p) for p in Path('Tests/PhotoVeilTests').glob('*.swift') if 'Benchmark' not in p.name]+['Tests/PhotoVeilIntegrationTests/VisionIntegrationTests.swift'],resources=[f'Tests/PhotoVeilUITests/Fixtures/{n}.jpg' for n in ['two-faces','faces-small-landscape','sample-card']])
smoke=target('PhotoVeilPRUITests',[str(p) for p in Path('Tests/PhotoVeilPRUITests').glob('*.swift')],ui=True)
p.write_bytes(plistlib.dumps(d,sort_keys=False));print(json.dumps({'core':core,'smoke':smoke}))
