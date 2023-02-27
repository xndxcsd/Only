// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract Only is Context, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public totalSupply;
    uint256 public constant ONLY_PRICE = 1000000000000000; // 0.001 ETH

    mapping(address => uint256) private balances;
    mapping(uint256 => mapping(address => address)) private allowances;

    // operator => owner
    mapping(address => address) private operators;

    mapping(uint256 => address) private tokenIdOwnerMapping;
    mapping(address => EnumerableSet.UintSet) private ownerTokenIdsMapping;

    mapping(address => address) private bindings;

    mapping(uint256 => bool) private hasTokenIdTransfered;
    mapping(uint256 => string) private transferData;

    mapping(uint256 => string) private tokenIdURIs;

    // implementing IERC165
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
    // end implementing IERC165

    // implementing IERC721

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance) {
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
        return __ownerOf(tokenId);
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
        __transfer(from, to, tokenId, data);
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
        __transfer(from, to, tokenId);
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
        __transfer(from, to, tokenId);
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
            _msgSender() == __ownerOf(tokenId),
            "the caller must own the token"
        );

        allowances[tokenId][_msgSender()] = to;

        emit Approval(_msgSender(), to, tokenId);
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
        require(operator != _msgSender(), "operator cannot be the caller");

        if (_approved) {
            operators[operator] = _msgSender();
        } else {
            delete operators[operator];
        }

        emit ApprovalForAll(_msgSender(), operator, _approved);
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
            tokenIdOwnerMapping[tokenId] == _msgSender(),
            "tokenId does not exist or not own by caller"
        );
        return __getApproved(_msgSender(), tokenId);
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

    // end implementing IERC721

    // implementing IERC721Metadata

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

    // end implementing IERC721Metadata

    function __transfer(address from, address to, uint256 tokenId) private {
        require(
            __isApprovedOrOwner(_msgSender(), tokenId),
            "caller is not the owner or approved to call"
        );
        require(
            from == __ownerOf(tokenId),
            "sender does not own the tokenId"
        );
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

    function __transfer(address from, address to, uint256 tokenId, bytes calldata data) private {
        require(data.length != 0, "data cannot be empty");
        
        transferData[tokenId] = string(data);
        __transfer(from, to, tokenId);
    }

    // prob expensive
    function getOwnedTokens() external view returns (uint256[] memory) {
        return ownerTokenIdsMapping[_msgSender()].values();
    }

    function getBound() external view returns (address) {
        address bound = bindings[_msgSender()];
        require(bound != address(0), "no bound");
        return bound;
    }


    function mint(uint256 nums) external payable {
        require(nums * ONLY_PRICE <= msg.value, "value sent is not enough");
        __mint(nums);
    }

    function mintAndBind(uint256 nums, address bound) external payable {
        require(nums * ONLY_PRICE <= msg.value, "value sent is not enough");
        bindings[_msgSender()] = bound;
        __mint(nums);
    }

    function __mint(uint256 nums) private {
        // start from totalSupply + 1 to ignore tokenid 0
        for (uint256 id = totalSupply + 1; id < totalSupply + nums + 1; id++) {
            tokenIdOwnerMapping[id] = _msgSender();
            ownerTokenIdsMapping[_msgSender()].add(id);
            // FIXME : use token[1,2,3].json for test
            tokenIdURIs[id] = __genMetaData((id%3)+1);
            balances[_msgSender()] += 1;

            emit Transfer(address(0), _msgSender(), id);
        }
        totalSupply += nums;        
    }

    function __bind(address from, address to) private {
        bindings[from] = to;
    }

    function __exists(uint256 tokenId) private view returns (bool) {
        return tokenIdOwnerMapping[tokenId] != address(0);
    }

    function __isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) private view returns (bool) {
        address owner = __ownerOf(tokenId);
        return (spender == owner ||
            spender == __getApproved(owner, tokenId) ||
            operators[spender] == owner);
    }

    function __genMetaData(
        uint256 tokenId
    ) private pure returns (string memory) {
        return
            string.concat(
                "ipfs://QmVFiqrFxqVVocc7qm5EKP5kGdBbYBrdGiJTMb8ybpCcEq/token",
                string.concat(tokenId.toString(), ".webp")
            );
    }

    function __ownerOf(uint256 tokenId) private view returns (address owner) {
        owner = tokenIdOwnerMapping[tokenId];

        require(owner != address(0), "tokenId does not exist");

        return owner;
    }

    function __getApproved(
        address owner,
        uint256 tokenId
    ) private view returns (address operator) {
        // FIXME : should return the operator which can operata all tokenIds for the caller?
        return allowances[tokenId][owner];
    }

}
