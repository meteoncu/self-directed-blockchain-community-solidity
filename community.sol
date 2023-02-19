pragma solidity ^0.8.0;

/*
    I am making the Chat GPT write this code. Logic and code needs many improvements. This is just a starting point.
*/

contract Community {
    struct Member {
        bool exists;
        bool approved;
    }

    struct MemberActions {
        bool join;
        bool remove;
        uint approvals;
        uint rejections;
        mapping (address => bool) votes;
    }

    address public admin;
    mapping (address => Member) public members;
    mapping (address => MemberActions) public memberActions;
    uint public memberCount;
    uint public minimumApprovals;
    uint public minimumRejections;
    bool public unanimousVoting;

    constructor() {
        admin = msg.sender;
        memberCount = 0;
        minimumApprovals = 1;
        minimumRejections = 1;
        unanimousVoting = false;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can perform this action.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender].exists, "Only members can perform this action.");
        _;
    }

    modifier notMember() {
        require(!members[msg.sender].exists, "You are already a member.");
        _;
    }

    function join() external notMember {
        memberActions[msg.sender].join = true;
        memberActions[msg.sender].votes[msg.sender] = true;
    }

    function remove() external onlyMember {
        memberActions[msg.sender].remove = true;
        memberActions[msg.sender].votes[msg.sender] = true;
    }

    function vote(address memberAddress, bool approval) external onlyMember {
        MemberActions storage actions = memberActions[memberAddress];
        require(actions.join || actions.remove, "This member action does not exist.");
        require(!actions.votes[msg.sender], "You have already voted on this member action.");

        actions.votes[msg.sender] = true;
        if (approval) {
            actions.approvals += 1;
        } else {
            actions.rejections += 1;
        }

        if (unanimousVoting) {
            if (actions.approvals == memberCount) {
                if (actions.join) {
                    members[memberAddress] = Member(true, true);
                    memberCount += 1;
                } else {
                    members[memberAddress].exists = false;
                    memberCount -= 1;
                }
                delete memberActions[memberAddress];
            } else if (actions.rejections == memberCount) {
                delete memberActions[memberAddress];
            }
        } else {
            if (actions.approvals >= minimumApprovals) {
                if (actions.join) {
                    members[memberAddress] = Member(true, true);
                    memberCount += 1;
                } else {
                    members[memberAddress].exists = false;
                    memberCount -= 1;
                }
                delete memberActions[memberAddress];
            } else if (actions.rejections >= minimumRejections) {
                delete memberActions[memberAddress];
            }
        }
    }

    function setMinimumApprovals(uint approvals) external onlyAdmin {
        minimumApprovals = approvals;
    }

    function setMinimumRejections(uint rejections) external onlyAdmin {
        minimumRejections = rejections;
    }

    function setUnanimousVoting(bool unanimous) external onlyAdmin {
        unanimousVoting = unanimous;
    }
}
