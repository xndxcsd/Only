// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Only is IERC721, IERC721Metadata {
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public totalSupply;
    uint256 public constant onlyPrice = 100000000000000000; // 0.1 ETH

    mapping(address => uint256) private balances;
    mapping(uint256 => mapping(address => address)) private allowances;

    // operator => owner
    mapping(address => address) private operators;

    mapping(uint256 => address) private tokenIdOwnerMapping;
    mapping(address => EnumerableSet.UintSet) private ownerTokenIdsMapping;

    mapping(address => address) private bindings;

    mapping(uint256 => bool) private hasTokenIdTransfered;

    mapping(uint256 => string) private tokenIdURIs;

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) external pure returns (bool) {
        return (interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId);
    }

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance) {
        require(msg.sender == owner, "cannot query the other's balance");
        return balances[owner];
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner) {
        owner = tokenIdOwnerMapping[tokenId];

        require(owner != address(0), "tokenId does not exist");

        return owner;
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`. If the sender didn't
     * have a address bound, bind the receiver in the function.
     *
     * Requirements:
     *
     * - the caller must be owner.
     * - `tokenId` token must exist and be owned by `from`.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` cannot have been transferd.
     * - `to` cannot be a contract.
     * - If there's an address bound for the caller, it must be `to`.
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external {
        address owner = this.ownerOf(tokenId);

        require(owner == msg.sender, "transfer caller is not owner");
        require(owner == from, "transfer of token that is not own");
        require(from != address(0), "sender address cannot be 0");
        require(to != address(0), "receiver address cannot be 0");

        require(
            hasTokenIdTransfered[tokenId] == false,
            "tokenId cannot be transfer second time"
        );
        require(
            to.isContract() == false,
            "cannot transfer token to a contract"
        );

        address bound = bindings[from];
        if (bound == address(0)) {
            // todo : test
            bound = to;
            __bind(from, to);
        } else {
            require(to == bound, "cannot transfer token to address not bound");
        }

        // update balance
        balances[from] -= 1;
        balances[to] += 1;

        // update holding
        ownerTokenIdsMapping[from].remove(tokenId);
        tokenIdOwnerMapping[tokenId] = to;
        ownerTokenIdsMapping[to].add(tokenId);

        // label transferd status
        hasTokenIdTransfered[tokenId] = true;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        this.safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external {
        this.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external {
        require(
            msg.sender == this.ownerOf(tokenId),
            "the caller must own the token"
        );

        allowances[tokenId][msg.sender] = to;

        emit Approval(msg.sender, to, tokenId);
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external {
        require(operator != msg.sender, "operator cannot be the caller");

        if (_approved) {
            operators[operator] = msg.sender;
        } else {
            delete operators[operator];
        }

        emit ApprovalForAll(msg.sender, operator, _approved);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * - `tokenId` must own by the caller.
     */
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator) {
        require(
            tokenIdOwnerMapping[tokenId] != msg.sender,
            "tokenId does not exist or not own by caller"
        );

        // FIXME : should return the operator which can operata all tokenIds for the caller?
        return allowances[tokenId][msg.sender];
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * Requirements:
     *
     * -
     * See {setApprovalForAll}
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool) {
        if (operators[operator] == owner) {
            return true;
        }
        return false;
    }

    function __bind(address from, address to) private {
        bindings[from] = to;
    }

    function __exists(uint256 tokenId) private view returns (bool) {
        return tokenIdOwnerMapping[tokenId] != address(0);
    }


    function mint(uint nums) external payable {

        require(nums * onlyPrice <= msg.value, "value sent is not enough");

        // start from totalSupply + 1 to ignore tokenid 0
        for (uint id = totalSupply + 1; id < totalSupply + nums + 1; id++) {
            tokenIdOwnerMapping[id] = msg.sender;
            ownerTokenIdsMapping[msg.sender].add(id);
            // TODO add a URI
            tokenIdURIs[id] = "";
            balances[msg.sender] += 1;
        }
        totalSupply += nums;
    }

    // override IERC721Metadata
    function name() external pure override returns (string memory) {
        return "Only";
    }

    function symbol() external pure override returns (string memory) {
        return "ONLY";
    }

    function tokenURI(
        uint256 tokenId
    ) external view override returns (string memory) {
        require(__exists(tokenId), "tokenId does not exist");
        return tokenIdURIs[tokenId];
    }
}
