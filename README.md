# MuMenu

### Interaction
![Diagram](Resources/Interaction.png)

### Components
![Diagram](Resources/Components.png)

### Design

MuMenu is both a namespace tree and controller. Navigating is similar to any other menu trees, with one key difference: it saves your place. Not, only for the last thing you done, but for everthing. The last thing you've done may be several levels deep and yet hovering over its main branch will automatically expend to show where you left off. Or, perhaps something a few days ago -- hovering over its part will reveal it. Automatically. So, each branch bookmarks its sub-branch, and that branch unfolds the sub-sub-branch, and so on. 

For example, let's say you have a 5^5 menu, averaging 5 choices and goes 5 levels deep. That would allow you to track 3,123 choices. With eye-tracking, that choice could be made in less than a second. Maybe. Perhaps, similar gains with an 8^8 menu wrapping 16 million choice? We don't know. It hasn't been tested. Yet. 

### Status

For now, MuMenu works with a toy: a visual Music synthesizer, called Deep Muse. The goal is to wrap about 2000 real-time parameters. It currently works on iOS and iPadOS, and a simulator for visionOS. 

The eyetracking and handpose is not yet available.

#### Naming convention for components
DeepMenu follows a MVVM pattern (Model, View, View Model) 

+ FloNode* - proxy for Model, such as NodeFlo
+ *View - SwiftUI View for [root,tree,branch,panel,node,leaf] 
+ *Vm   - View Model for [root,tree,branch,panel,node,leaf] 

##### Root* - starting point for one of more Tree(s)
+ RootVm - touch, corner, pilot, trees, branchSpot, nodeSpot
+ RootView - manage UIViews for each corner 
+ RootStatus - publish changed state in [root,tree,edit,space]

##### Tree* - horizontal or vertical hierarcy of Branches 
+ TreeVm - select FloNode, add or remove sub-branches
+ TreeView - SwiftUI view collection of Branch's 

##### Branch* - one level in a hierachy containing Nodes
+ BranchVm - view model of a branch
+ BranchView - SwiftUI view collection of NodeViews
+ BranchPanelView - background panel for BranchView
        
##### FloNode* - A persistent model of items (shared by many *Vms) 
+ FloNode - a generic node, may be shared my many NodeVm's (and views)
+ NodeFlo - a node proxy for Flo items 
+ NodeVm - a view model for a View, may share a Node from another Vm
+ NodeView - a SwiftUI view, has a companion NodeVm
+ NodeIconView - a subview of NodeView for icons
+ NodeTextView - a subview of NodeView for text
        
##### Leaf* - subclass of FloNode with a user touch control  
+ LeafTap - tap to activate, like a drum pad
+ LeafTog - toggle a switch 0 or 1
+ LeafSeg - segmented control
+ LeafVal - single dimension value
+ LeafVxy - 2 dimension xy control
   
#####Panel* - stroke+fill branches and bounds for node views
+ PanelVm - type, axis, size, and margins for View
+ PanelView - SwiftUI background 
+ PanelAxisView - vertical or horizontal PanelView 

##### Corner* - Corner start of menu
  - CornerVm - state for selection ring and logo nodes
  - CornerView - view for selection ring and logo nodes

##### Touch* - capture touches which are captured by all branches
  - Touch - manage touch's [begin,moved,ended] state plus taps
 
##### Prefixes and Suffixes
+ component instances 
  - *Vm - instance of view model, such as branchVm
  - *Vms - array of [*Vm], such as branchVms
+ point, size, radius, spacing 
  - x* - x in a CGPoint(x:y:)
  - y* - y in a CGPoint(x:y:)
  - w* - width  in CGSize(width:height)
  - h* - height in CGSize(width:height)
  - r* - radius / distance from center of a node
  - s* - spacing between nodes
+ hierarchy
  - spot* - spotlight on current Node or Branch
  - parent* - parent in model hierarchy
  - children* - [child] array in model hierarchy
  - child - current child in for loop
  - super - a parent in a view hierarchy
  - sub - a child in view hierarcy
             
### Relationships between classes and structs 
+ `treeVm ▹▹ branchVm ▹▹ nodeVm ▹ leafVm ◃◃ node`
  - treeVm   to branchVm {1,}   // 1:M array [branchVm]s expanded  
  - branchVm to nodeVm   {1,}   // 1:M a branchVm has 1 or more nodeVms
  - nodeVm   to leafVm   {0,1}  // 1:1 optional leaf
  - leafVm   to node     {1,1}  // 1:1 one branchVm for each nodeVm    
  - node     to leafVm   {0,}   // 1:M may be shared by many or cached

### logging symbols
  - `0.00 🟢` start touch at time 0.00  
  - `0.44 🔴` end touch at delta time 0.44
  - `0.33 🟣¹` single tap (² double, ³ triple, etc)
  - `touch∙(393, 675)` coordinate of touch event
  - `🧺` found cached instance
  - `√` `𐂷` `✎` `⬚` - status: .root .tree .edit .space
  - `V⃝ 1⇨0=0` vertical branch from single level to hidden 
  - `H⃝ 0⇨1=1` horzontal branch from hidden to single level
