import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/domain/city/building_type.dart';
import 'package:math_city/domain/city/construction_site.dart';
import 'package:math_city/domain/city/land_blocks.dart';
import 'package:math_city/domain/city/placement_rules.dart';
import 'package:math_city/domain/city/population_model.dart';
import 'package:math_city/domain/city/upgrade_ladders.dart';
import 'package:math_city/domain/economy/question_block.dart';
import 'package:math_city/domain/proficiency/proficiency_band.dart';

BuildingType _type(String id) => findBuildingTypeById(id)!;

ConstructionSite _homeSite({int paid = 0}) => ConstructionSite(
  goal: BuildingGoal(type: _type('single_home'), col: 0, row: 0),
  startedAtRound: 1,
  paidCoins: paid,
);

void main() {
  group('stageForFraction', () {
    test('draft thresholds 0 / ⅓ / ⅔ / done', () {
      expect(stageForFraction(0), 0);
      expect(stageForFraction(0.33), 0);
      expect(stageForFraction(1 / 3), 1);
      expect(stageForFraction(0.5), 1);
      expect(stageForFraction(2 / 3), 2);
      expect(stageForFraction(0.99), 2);
      expect(stageForFraction(1), kSiteOpenStage);
    });
  });

  group('ConstructionSite', () {
    test('a fresh site owes the full price at stage 0', () {
      final s = _homeSite();
      expect(s.price, 60);
      expect(s.paidCoins, 0);
      expect(s.remaining, 60);
      expect(s.paidFraction, 0);
      expect(s.stage, 0);
      expect(s.isFull, isFalse);
    });

    test('paid fraction drives the stage', () {
      expect(_homeSite(paid: 19).stage, 0);
      expect(_homeSite(paid: 20).stage, 1);
      expect(_homeSite(paid: 40).stage, 2);
      expect(_homeSite(paid: 60).stage, kSiteOpenStage);
    });

    test('a free goal is full from the start', () {
      final s = ConstructionSite(
        goal: BuildingGoal(type: _type('mayors_office'), col: 0, row: 0),
        startedAtRound: 0,
      );
      expect(s.price, 0);
      expect(s.isFull, isTrue);
      expect(s.paidFraction, 1);
      expect(s.stage, kSiteOpenStage);
      expect(s.remaining, 0);
    });

    test('payIn accumulates and reports stage changes', () {
      final r1 = _homeSite().payIn(15);
      expect(r1.accepted, 15);
      expect(r1.overflow, 0);
      expect(r1.site.paidCoins, 15);
      expect(r1.stageAdvanced, isFalse);
      expect(r1.opened, isFalse);

      final r2 = r1.site.payIn(10);
      expect(r2.site.paidCoins, 25);
      expect(r2.stageBefore, 0);
      expect(r2.site.stage, 1);
      expect(r2.stageAdvanced, isTrue);
      expect(r2.opened, isFalse);
    });

    test('open-on-full: the payment that reaches the price opens the site', () {
      final r = _homeSite(paid: 50).payIn(10);
      expect(r.site.isFull, isTrue);
      expect(r.site.stage, kSiteOpenStage);
      expect(r.opened, isTrue);
      expect(r.overflow, 0);
    });

    test('the bar never exceeds the price; excess is overflow', () {
      final r = _homeSite(paid: 50).payIn(25);
      expect(r.accepted, 10);
      expect(r.overflow, 15);
      expect(r.site.paidCoins, 60);
      expect(r.opened, isTrue);
    });

    test('paying into a full site accepts nothing and does not re-open', () {
      final r = _homeSite(paid: 60).payIn(7);
      expect(r.accepted, 0);
      expect(r.overflow, 7);
      expect(r.opened, isFalse);
      expect(r.stageAdvanced, isFalse);
    });

    test('payReward pays answer coins plus band bonus', () {
      final reward = AnswerReward(
        correct: true,
        coins: 12,
        streakCount: 3,
        bandBonuses: [
          BandCrossingBonus(
            conceptId: 'x',
            band: ProficiencyBand.values.first,
            coins: 20,
          ),
        ],
      );
      final r = _homeSite().payReward(reward);
      expect(r.accepted, 32);
      expect(r.site.paidCoins, 32);
    });

    test('a wrong answer pays nothing', () {
      const reward = AnswerReward(correct: false, coins: 0, streakCount: 0);
      final r = _homeSite(paid: 30).payReward(reward);
      expect(r.accepted, 0);
      expect(r.site.paidCoins, 30);
      expect(r.site.stage, 1);
    });

    test('pay-in is immutable and keeps startedAtRound', () {
      final s = _homeSite();
      final r = s.payIn(10);
      expect(s.paidCoins, 0);
      expect(r.site.startedAtRound, s.startedAtRound);
    });

    test('a building goal moves like a building, keeping its coins', () {
      final s = _homeSite(paid: 30);
      final goal = s.goal as BuildingGoal;
      final moved = s.copyWith(goal: goal.movedTo(col: 5, row: 7));
      expect(moved.paidCoins, 30);
      final g = moved.goal as BuildingGoal;
      expect((g.col, g.row), (5, 7));
      expect(g.footprint.tiles().first, (5, 7));
      expect(g.type.id, 'single_home');
    });

    test('footprint follows the building type', () {
      final g = BuildingGoal(type: _type('apartment'), col: 2, row: 3);
      expect(g.footprint.width, 2);
      expect(g.footprint.height, 2);
      expect(g.footprint.tiles().toSet(), {(2, 3), (3, 3), (2, 4), (3, 4)});
    });
  });

  group('upgrade sites', () {
    final home = _type('single_home');
    final apartment = _type('apartment');
    final upgradeGoal = BuildingGoal(
      type: apartment,
      col: 0,
      row: 0,
      upgrade: UpgradeLink(sourcePlacementId: 42, sourceType: home),
    );

    test('priced at target − source', () {
      expect(upgradeGoal.isUpgrade, isTrue);
      expect(upgradeGoal.price, apartment.coinCost - home.coinCost);
      expect(upgradeGoal.price, 60);
    });

    test('a new build of the same type is full price', () {
      expect(BuildingGoal(type: apartment, col: 0, row: 0).price, 120);
    });

    test('net population on open is target − source', () {
      expect(upgradeGoal.netPopulationOnOpen, 16 - 4);
      expect(
        BuildingGoal(type: apartment, col: 0, row: 0).netPopulationOnOpen,
        16,
      );
    });

    test('the old building counts until the upgrade opens', () {
      // Population capacity is a function of *placed* buildings only; an open
      // upgrade site contributes nothing, and opening it swaps source for
      // target — a net change equal to netPopulationOnOpen.
      final placedBefore = [_type('mayors_office'), home];
      final before = populationCapacity(placedBefore);
      expect(before, home.populationContribution);

      final placedAfter = [_type('mayors_office'), apartment];
      final after = populationCapacity(placedAfter);
      expect(after - before, upgradeGoal.netPopulationOnOpen);
    });

    test('the upgrade link keeps the source placement id across a move', () {
      final moved = upgradeGoal.movedTo(col: 9, row: 9);
      expect(moved.upgrade!.sourcePlacementId, 42);
      expect(moved.price, 60);
    });

    test('the upgrade footprint may sit over its own source', () {
      // Excluding the source from `existing` (as for a move) lets the grown
      // 2×2 footprint cover the 1×1 home's tile.
      final owned = ownedTilesOf(startingOwnedBlocks());
      const source = GridFootprint(col: 0, row: 0, width: 1, height: 1);
      final check = checkPlacement(
        ownedTiles: owned,
        existing: const [],
        candidate: upgradeGoal.footprint,
      );
      expect(check.isLegal, isTrue);
      expect(upgradeGoal.footprint.tiles(), contains((source.col, source.row)));
    });
  });

  group('land block sites', () {
    test('priced on the land ladder', () {
      const g = LandBlockGoal(blockX: 2, blockY: 0);
      expect(g.price, blockCost(2, 0));
      expect(g.price, 1200);
      expect(const LandBlockGoal(blockX: -3, blockY: 1).price, 1800);
    });

    test('pays down like any site', () {
      const site = ConstructionSite(
        goal: LandBlockGoal(blockX: 2, blockY: 0),
        startedAtRound: 3,
      );
      final r = site.payIn(400);
      expect(r.site.stage, 1);
      expect(r.site.remaining, 800);
      expect(site.payIn(1200).opened, isTrue);
    });
  });

  group('checkStartSite', () {
    final owned = startingOwnedBlocks();
    final home = _type('single_home');
    final apartment = _type('apartment');

    ConstructionSite site(SiteGoal g) =>
        ConstructionSite(goal: g, startedAtRound: 0);

    test('a plain building goal on an empty city is fine', () {
      expect(
        checkStartSite(
          goal: BuildingGoal(type: home, col: 0, row: 0),
          openSites: const [],
          ownedBlocks: owned,
        ),
        isNull,
      );
    });

    test('a fourth open site is refused', () {
      final three = [
        for (var i = 0; i < kMaxOpenSites; i++)
          site(BuildingGoal(type: home, col: i * 2, row: 0)),
      ];
      expect(three.length, 3);
      expect(
        checkStartSite(
          goal: BuildingGoal(type: home, col: 8, row: 0),
          openSites: three,
          ownedBlocks: owned,
        ),
        SiteStartRejection.tooManyOpenSites,
      );
      expect(
        checkStartSite(
          goal: BuildingGoal(type: home, col: 8, row: 0),
          openSites: three.take(2),
          ownedBlocks: owned,
        ),
        isNull,
      );
    });

    test('the cap applies to land and upgrade goals too', () {
      final three = [
        for (var i = 0; i < kMaxOpenSites; i++)
          site(BuildingGoal(type: home, col: i * 2, row: 0)),
      ];
      expect(
        checkStartSite(
          goal: const LandBlockGoal(blockX: 2, blockY: 0),
          openSites: three,
          ownedBlocks: owned,
        ),
        SiteStartRejection.tooManyOpenSites,
      );
    });

    test('an upgrade must be the rung directly above its source', () {
      final skip = BuildingGoal(
        type: _type('high_rise'),
        col: 0,
        row: 0,
        upgrade: UpgradeLink(sourcePlacementId: 1, sourceType: home),
      );
      expect(
        checkStartSite(goal: skip, openSites: const [], ownedBlocks: owned),
        SiteStartRejection.notAnUpgradeStep,
      );
      final step = BuildingGoal(
        type: apartment,
        col: 0,
        row: 0,
        upgrade: UpgradeLink(sourcePlacementId: 1, sourceType: home),
      );
      expect(
        checkStartSite(goal: step, openSites: const [], ownedBlocks: owned),
        isNull,
      );
    });

    test('a building can be the source of only one open upgrade', () {
      final first = BuildingGoal(
        type: apartment,
        col: 0,
        row: 0,
        upgrade: UpgradeLink(sourcePlacementId: 7, sourceType: home),
      );
      final again = first.movedTo(col: 4, row: 4);
      expect(
        checkStartSite(
          goal: again,
          openSites: [site(first)],
          ownedBlocks: owned,
        ),
        SiteStartRejection.sourceAlreadyUpgrading,
      );
      final other = BuildingGoal(
        type: apartment,
        col: 4,
        row: 4,
        upgrade: UpgradeLink(sourcePlacementId: 8, sourceType: home),
      );
      expect(
        checkStartSite(
          goal: other,
          openSites: [site(first)],
          ownedBlocks: owned,
        ),
        isNull,
      );
    });

    test('a land site must touch owned land by an edge', () {
      expect(
        checkStartSite(
          goal: const LandBlockGoal(blockX: 2, blockY: 0),
          openSites: const [],
          ownedBlocks: owned,
        ),
        isNull,
      );
      expect(
        checkStartSite(
          goal: const LandBlockGoal(blockX: 2, blockY: 2),
          openSites: const [],
          ownedBlocks: owned,
        ),
        SiteStartRejection.blockNotPurchasable,
      );
      expect(
        checkStartSite(
          goal: const LandBlockGoal(blockX: 0, blockY: 0),
          openSites: const [],
          ownedBlocks: owned,
        ),
        SiteStartRejection.blockNotPurchasable,
        reason: 'already owned',
      );
    });

    test('one site per land block', () {
      const g = LandBlockGoal(blockX: 2, blockY: 0);
      expect(
        checkStartSite(goal: g, openSites: [site(g)], ownedBlocks: owned),
        SiteStartRejection.blockAlreadyStarted,
      );
    });
  });

  group('catalog coverage', () {
    test('every building can be started as a site', () {
      for (final b in buildingRegistry) {
        final s = ConstructionSite(
          goal: BuildingGoal(type: b, col: 0, row: 0),
          startedAtRound: 0,
        );
        expect(s.price, b.coinCost, reason: b.id);
        expect(
          checkStartSite(
            goal: s.goal,
            openSites: const [],
            ownedBlocks: startingOwnedBlocks(),
          ),
          isNull,
          reason: b.id,
        );
        final full = s.payIn(b.coinCost);
        expect(full.site.isFull, isTrue, reason: b.id);
        expect(full.site.stage, kSiteOpenStage, reason: b.id);
        expect(full.overflow, 0, reason: b.id);
        // Free goals are already open; everything else opens on this payment.
        expect(full.opened, b.coinCost > 0, reason: b.id);
      }
    });

    test('every ladder step can be started as an upgrade site', () {
      for (final ladder in upgradeLadders) {
        for (var i = 0; i + 1 < ladder.length; i++) {
          final source = _type(ladder[i]);
          final target = _type(ladder[i + 1]);
          final goal = BuildingGoal(
            type: target,
            col: 0,
            row: 0,
            upgrade: UpgradeLink(sourcePlacementId: i, sourceType: source),
          );
          expect(
            goal.price,
            target.coinCost - source.coinCost,
            reason: target.id,
          );
          expect(goal.price, greaterThan(0), reason: target.id);
          expect(
            checkStartSite(
              goal: goal,
              openSites: const [],
              ownedBlocks: startingOwnedBlocks(),
            ),
            isNull,
            reason: target.id,
          );
        }
      }
    });
  });
}
