'use client';

import { useEffect, useState } from 'react';

import { useDebounce, useLocalStorage } from '@react-hooks-library/core';
import {
  Download,
  File,
  Folder,
  FolderPlus,
  PanelBottomOpen,
  PanelTopOpen,
  Pencil,
  RefreshCw,
  Save,
  SquareChevronDown,
  SquareChevronRight,
  Trash2,
  X,
} from 'lucide-react';
import { Tree, TreeApi } from 'react-arborist';
import './styles.css';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';

const MAXCHARACTERS = 80;

const TreeArboristComponentRemote = () => {
  const prefix = 'pl-';
//   const [apiResponse] = useLocalStorage<string>(prefix + bookmarkId, '[]');

//   const prefixtree = 'tree-';
//   const [treeState, setTreeState] = useLocalStorage(
//     prefixtree + bookmarkId,
//     '',
//   );

  const data = [
    {
      id: "1",
      name: "public",
      children: [{ id: "c1-1", name: "index.html" }]
    },
    {
      id: "2",
      name: "src",
      children: [
        { id: "c2-1", name: "App.js" },
        { id: "c2-2", name: "index.js" },
        { id: "c2-3", name: "styles.css" }
      ]
    },
    { id: "3", name: "package.json" },
    { id: "4", name: "README.md" }
  ];

  const [tree, setTree] = useState<TreeApi<any> | null>(null);
  const [isDataLoaded, setIsDataLoaded] = useState(false);
  const [fileName, setFileName] = useState('bookmarks.html');
  const [selectAllToggle, setSelectAllToggle] = useState(true);
  const [openAllToggle, setOpenAllToggle] = useState(true);
  const [term, setTerm] = useState('');
  const debouncedTerm = useDebounce(term, 1000);

  const [treeDimensions, setTreeDimensions] = useState({
    width: 1000,
    height: 800,
  });

  const size = 0.7;
  useEffect(() => {
    const handleResize = () => {
      setTreeDimensions({
        width: window.innerWidth * size, // Example: 80% of the window width
        height: window.innerHeight * size, // Example: 80% of the window height
      });
    };

    window.addEventListener('resize', handleResize);
    handleResize(); // Set initial dimensions

    return () => {
      window.removeEventListener('resize', handleResize);
    };
  }, []);

  useEffect(() => {
    setIsDataLoaded(true);
  }, []);

  const handleSelectToggle = () => {
    if (selectAllToggle) {
      tree?.selectAll();
    } else {
      tree?.deselectAll();
    }
    setSelectAllToggle(!selectAllToggle);
  };

  const handleOpenCloseToggle = () => {
    if (openAllToggle) {
      tree?.openAll();
    } else {
      tree?.closeAll();
    }
    setOpenAllToggle(!openAllToggle);
  };

  return (
    <div className="flex w-full flex-col">
      <div className="flex flex-row items-center space-x-1">
        <div className="relative w-full max-w-md p-2">
          <Input
            className="pr-10"
            placeholder="Search... "
            type="text"
            value={term}
            onChange={(e) => setTerm(e.currentTarget.value)}
          />
          <Button
            className="absolute right-3 top-1/2 -translate-y-1/2"
            size="icon"
            variant="ghost"
            onClick={() => setTerm('')}
          >
            <X className="h-5 w-5" />
          </Button>
        </div>
        <Button
          onClick={handleOpenCloseToggle}
          style={{ width: '50px' }}
          title={openAllToggle ? 'Open All' : 'Close All'}
        >
          {openAllToggle ? <PanelTopOpen /> : <PanelBottomOpen />}
        </Button>
        <Button
          onClick={() => tree?.createInternal()}
          style={{ width: '50px' }}
          title="New Category"
        >
          {<FolderPlus />}
        </Button>
        {/* <Button
          style={{ width: '50px' }}
          onClick={handleEditSubmit}
          title="Sync Bookmarks"
        >
          <RefreshCw />
        </Button> */}
        {/* <Button
          className="bg-red-500 hover:bg-red-500"
          style={{ width: '100px' }}
          onClick={handleDownloadClick}
          title="Download Bookmarks"
        >
          <Download /> Export
        </Button> */}
        {/* <TooltipComponent /> */}
      </div>
      <div className="flex w-full flex-col">
        {/* {isDataLoaded && treeData.length > 0 && ( */}
        {isDataLoaded && (
          <Tree
            initialData={data}
            ref={(t) => {
              if (t) setTree(t);
            }}
            openByDefault={false}
            // width={1000}
            // height={800}
            width={treeDimensions.width}
            height={treeDimensions.height}
            indent={24}
            rowHeight={36}
            paddingTop={30}
            paddingBottom={10}
            padding={25}
            searchTerm={debouncedTerm}
          >
            {Node}
          </Tree>
        )}
      </div>
    </div>
  );
};

export default TreeArboristComponentRemote;

function Node({
  node,
  style,
  dragHandle,
  tree,
}: any) {
  const handleDelete = () => {
    if (window.confirm('Are you sure you want to delete this node?')) {
      tree.delete(node.id);
    }
  };

  return (
    <div className="node-container" style={style} ref={dragHandle}>
      <div
        className="node-content"
        onClick={() => node.isInternal && node.toggle()}
      >
        {node.isLeaf ? (
          <>
            <span className="arrow"></span>
            <span className="file-folder-icon">
              <File color="#5c5c5c " />
            </span>
          </>
        ) : (
          <>
            <span className="arrow">
              {node.isOpen ? (
                <SquareChevronDown color="#5c5c5c " />
              ) : (
                <SquareChevronRight color="#5c5c5c " />
              )}
            </span>
            <span className="file-folder-icon">
              <Folder color="#f6cf60 " />
            </span>
          </>
        )}
        <span className="node-text">
          {node.isEditing ? (
            <input
              type="text"
              name="title"
              // defaultValue={
              //   node.data.title.length > MAXCHARACTERS
              //     ? node.data.title.slice(0, MAXCHARACTERS) + '...'
              //     : node.data.title
              // }
              defaultValue={node.data.name}
              onFocus={(e) => e.currentTarget.select()}
              onBlur={() => node.reset()}
              onKeyDown={(e) => {
                if (e.key === 'Escape') node.reset();
                if (e.key === 'Enter')
                  node.submit((node.data.name = e.currentTarget.value));
              }}
              autoFocus
            />
          ) : (
            <span>
              {((node.data.name) ?? '').length > MAXCHARACTERS
                ? ((node.data.name) ?? '').slice(
                    0,
                    MAXCHARACTERS,
                  ) + '...'
                : ((node.data.name) ?? '')}
            </span>
          )}
        </span>
        <div className="node-text flex flex-row">
          <div
            className="icon-small"
            onClick={() => node.edit()}
            title="Rename..."
            role="button"
            tabIndex={0}
            onKeyPress={(e) => {
              if (e.key === 'Enter') node.edit();
            }}
          >
            <Pencil className="icon-small" color="#5c5c5c " />
          </div>
          <div
            className="icon-small"
            onClick={handleDelete}
            title="Delete"
            role="button"
            tabIndex={0}
            onKeyPress={(e) => {
              if (e.key === 'Enter') handleDelete();
            }}
          >
            <Trash2 className="icon-small" color="#5c5c5c " />
          </div>
        </div>
      </div>
    </div>
  );
}
