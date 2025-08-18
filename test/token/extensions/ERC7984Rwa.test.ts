import { expect } from 'chai';
import { ethers } from 'hardhat';

/* eslint-disable no-unexpected-multiline */
describe('ERC7984Rwa', function () {
  async function deployFixture() {
    const [admin, agent1, agent2, recipient, anyone] = await ethers.getSigners();
    const token = await ethers.deployContract('ERC7984RwaMock', ['name', 'symbol', 'uri']);
    token.connect(anyone);
    return { token, admin, agent1, agent2, recipient, anyone };
  }

  describe('Pausable', async function () {
    it('should pause & unpause', async function () {
      const { token, admin, agent1 } = await deployFixture();
      await token
        .connect(admin)
        .addAgent(agent1)
        .then(tx => tx.wait());
      for (const manager of [admin, agent1]) {
        expect(await token.paused()).is.false;
        await token
          .connect(manager)
          .pause()
          .then(tx => tx.wait());
        expect(await token.paused()).is.true;
        await token
          .connect(manager)
          .unpause()
          .then(tx => tx.wait());
        expect(await token.paused()).is.false;
      }
    });

    it('should not pause if neither admin nor agent', async function () {
      const { token, anyone } = await deployFixture();
      await expect(token.connect(anyone).pause())
        .to.be.revertedWithCustomError(token, 'UnauthorizedSender')
        .withArgs(anyone);
    });

    it('should not unpause if neither admin nor agent', async function () {
      const { token, anyone } = await deployFixture();
      await expect(token.connect(anyone).unpause())
        .to.be.revertedWithCustomError(token, 'UnauthorizedSender')
        .withArgs(anyone);
    });
  });

  describe('Roles', async function () {
    it('should check admin', async function () {
      const { token, admin, anyone } = await deployFixture();
      expect(await token.isAdmin(admin)).is.true;
      expect(await token.isAdmin(anyone)).is.false;
    });

    it('should check/add/remove agent', async function () {
      const { token, admin, agent1 } = await deployFixture();
      expect(await token.isAgent(agent1)).is.false;
      await token
        .connect(admin)
        .addAgent(agent1)
        .then(tx => tx.wait());
      expect(await token.isAgent(agent1)).is.true;
      await token
        .connect(admin)
        .removeAgent(agent1)
        .then(tx => tx.wait());
      expect(await token.isAgent(agent1)).is.false;
    });

    it('should not add agent if neither admin nor agent', async function () {
      const { token, agent1, anyone } = await deployFixture();
      await expect(token.connect(anyone).addAgent(agent1))
        .to.be.revertedWithCustomError(token, 'UnauthorizedSender')
        .withArgs(anyone);
    });

    it('should not remove agent if neither admin nor agent', async function () {
      const { token, agent1, anyone } = await deployFixture();
      await expect(token.connect(anyone).removeAgent(agent1))
        .to.be.revertedWithCustomError(token, 'UnauthorizedSender')
        .withArgs(anyone);
    });
  });
});
/* eslint-disable no-unexpected-multiline */
