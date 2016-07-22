import Darwin

typealias NodeData = protocol<Comparable, CustomStringConvertible>

// A red-black tree implementation with only insertion operations
class Tree<T: NodeData> {
    var root: Node<T>!
    var size: Int

    init() {
        root = nil
        size = 0
    }

    // Return an array inorder traversal
    func toArray() -> [T] {
        var stack = [Node<T>]()
        var array = [T]()
        var node = root
        while stack.count != 0 || node != nil {
            if node != nil {
                stack.append(node)
                node = node.left
            }
            else {
                node = stack.popLast()
                array.append(node.data)
                node = node.right
            }
        }
        return array
    }

    // Return the added node
    func treeInsert(data: T) -> Node<T> {
        size += 1
        guard var currentNode = root else {
            root = Node(data)
            return root
        }
        while true {
            if data > currentNode.data {
                if let right = currentNode.right {
                    currentNode = right
                }
                else {
                    let newNode = Node(data)
                    currentNode.right = newNode
                    newNode.parent = currentNode
                    return newNode
                }
            }
            else if data < currentNode.data {
                if let left = currentNode.left {
                    currentNode = left
                }
                else {
                    let newNode = Node(data)
                    currentNode.left = newNode
                    newNode.parent = currentNode
                    return newNode
                }
            }
            else {
                size -= 1
                break
            }
        }
        return currentNode
    }

    // Check and maintain conditions for a red-black tree
    func insert(data: T) {
        // Insert `data` using binary tree insertion
        var node = treeInsert(data)

        // Restore the red-black property
        while node != root && node.parent.color == .Red {
            guard var grandparent = node.parent.parent else {
                // Break if node has no grandparent. No violation can occur
                break
            }
            var parent = node.parent
            // `parent` is a left child
            if parent == grandparent.left {
                if let uncle = grandparent.right where uncle.color == .Red {
                    // Case 1 - change the colors
                    parent.color = .Black
                    uncle.color = .Black
                    grandparent.color = .Red

                    // Move node up the tree
                    node = grandparent
                }
                // `uncle` is black
                else {
                    // node is a right child
                    if node === parent.right {
                        // Case 2 - move node up and rotate
                        leftRotate(parent)
                        node = node.left
                        parent = node.parent
                        grandparent = parent.parent
                    }
                    // Case 3
                    parent.color = .Black
                    grandparent.color = .Red
                    rightRotate(grandparent)
                }
            }
            // `parent` is a right child
            else {
                if let uncle = grandparent.left where uncle.color == .Red {
                    parent.color = .Black
                    uncle.color = .Black
                    grandparent.color = .Red
                    node = grandparent
                }
                else {
                    if node === parent.left {
                        rightRotate(parent)
                        node = node.right
                        parent = node.parent
                        grandparent = parent.parent
                    }
                    parent.color = .Black
                    grandparent.color = .Red
                    leftRotate(grandparent)
                }
            }
        }
        // Make `root` black
        root.color = .Black
    }

    // Function for inserting elements from a collection
    func insert<S: SequenceType where S.Generator.Element == T>(items: S) {
        for item in items {
            insert(item)
        }
    }

    func leftRotate(node: Node<T>) {
        let savedParent = node.parent
        let newNode = node.right
        node.right = newNode.left
        if node.right != nil {
            node.right.parent = node
        }
        newNode.left = node
        node.parent = newNode
        newNode.parent = savedParent
        if savedParent == nil {
            root = newNode
            return
        }
        if node == savedParent!.left {
            savedParent.left = newNode
        }
        else {
            savedParent.right = newNode
        }
    }

    func rightRotate(node: Node<T>) {
        let savedParent = node.parent
        let newNode = node.left
        node.left = newNode.right
        if newNode.left != nil {
            newNode.left.parent = node
        }
        newNode.right = node
        node.parent = newNode
        newNode.parent = savedParent
        if savedParent == nil {
            root = newNode
            return
        }
        if node == savedParent.left {
            savedParent.left = newNode
        }
        else {
            savedParent.right = newNode
        }
    }
}

extension Tree: SequenceType {
    func generate() -> TreeGenerator<T> {
        return TreeGenerator<T>(root)
    }
}

struct TreeGenerator<T: NodeData>: GeneratorType {
    typealias Element = T

    var node: Node<T>!

    init(_ root: Node<T>!) {
        node = root
        if root == nil {
            return
        }
        while node.left != nil {
            node = node.left
        }
    }

    // Inorder traversal
    mutating func next() -> Element? {
        guard let r = node else {
            return nil
        }
        // If right exists, go right, then go fully left
        if node.right != nil {
            node = node.right
            while node.left != nil {
                node = node.left
            }
            return r.data
        }
        // Walk up until we come from left
        else {
            while true {
                if node.parent == nil {
                    node = nil
                    return r.data
                }
                if node.parent.left === node {
                    node = node.parent
                    return r.data
                }
                node = node.parent
            }
        }
    }
}

class Node<T: NodeData>: NodeData {
    let data: T
    var left, right: Node<T>!
    weak var parent: Node<T>!
    var color: Color

    var description: String {
        return "Node(\(data))"
    }

    init(_ data: T) {
        self.data = data
        self.color = .Red
    }
}

enum Color {
    case Red, Black
}

func ==<T>(left: Node<T>, right: Node<T>) -> Bool {
    return left.data == right.data
}

func <<T>(left: Node<T>, right: Node<T>) -> Bool {
    return left.data < right.data
}
