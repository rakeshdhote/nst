"use client";

import {
    UncontrolledTreeEnvironment,
    Tree,
    StaticTreeDataProvider,
  } from "react-complex-tree";
import { longTree } from './treeData'; // Import the tree data
import { JSX } from 'react';
import "react-complex-tree/lib/style-modern.css";

// export default function TreeComponent(): JSX.Element {
//     return (
//         <>
//             <UncontrolledTreeEnvironment
//                 canDragAndDrop={true}
//                 canDropOnFolder={true}
//                 canReorderItems={true}
//                 canSearch={true}
//                 canRename={true}
//                 dataProvider={new StaticTreeDataProvider(longTree.items, (item, data) => ({ ...item, data }))}
//                 getItemTitle={item => item.data}
//                 viewState={{ 'tree-1': {}, 'tree-2': {} }}
//             >
//                 <div
//                     style={{
//                         display: 'flex',
//                         justifyContent: 'space-evenly',
//                         alignItems: 'baseline',
//                         padding: '20px 0',
//                     }}
//                 >
//                     <div style={{ width: '28%', backgroundColor: 'white' }}>
//                         <Tree treeId="tree-1" rootItem="root" treeLabel="Tree 1" />
//                     </div>
//                     <div style={{ width: '28%', backgroundColor: 'white' }}>
//                         <Tree treeId="tree-2" rootItem="root" treeLabel="Tree 2" />
//                     </div>
//                 </div>
//             </UncontrolledTreeEnvironment>
//         </>
//     );
// };

// export default TreeComponent;

export default function TreeComponent() {
    return (
      <UncontrolledTreeEnvironment
        dataProvider={
          new StaticTreeDataProvider(longTree.items, (item, data) => ({
            ...item,
            data,
          }))
        }
        getItemTitle={(item) => item.data}
        canDragAndDrop={true}
        canReorderItems={true}
        canDropOnFolder={true}
        canDropOnNonFolder={true}
        viewState={{
          "tree-1": {
            expandedItems: ["Fruit"],
          },
        }}
      >
        <Tree treeId="tree-1" rootItem="root" treeLabel="Tree Example" />
      </UncontrolledTreeEnvironment>
    );
  }