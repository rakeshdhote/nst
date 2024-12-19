"use client";

import { UncontrolledTreeEnvironment, StaticTreeDataProvider, Tree } from 'react-complex-tree'; 
import { longTree } from './treeData'; // Import the tree data
import 'react-complex-tree/lib/style-modern.css';
const TreeComponent = () => {
    return (
        <>
            <UncontrolledTreeEnvironment
                canDragAndDrop={true}
                canDropOnFolder={true}
                canReorderItems={true}
                dataProvider={new StaticTreeDataProvider(longTree.items, (item, data) => ({ ...item, data }))}
                getItemTitle={item => item.data}
                viewState={{}}
            >
                <div
                    style={{
                        display: 'flex',
                        justifyContent: 'space-evenly',
                        alignItems: 'baseline',
                        padding: '20px 0',
                    }}
                >
                    <div style={{ width: '28%', backgroundColor: 'white' }}>
                        <Tree treeId="tree-1" rootItem="root" treeLabel="Tree 1" />
                    </div>
                    <div style={{ width: '28%', backgroundColor: 'white' }}>
                        <Tree treeId="tree-2" rootItem="root" treeLabel="Tree 2" />
                    </div>
                </div>
            </UncontrolledTreeEnvironment>
        </>
    );
};

export default TreeComponent;