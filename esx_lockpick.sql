USE `essentialmode`;


INSERT INTO `items` (`name`, `label`, `limit`, `rare`, `can_remove`) VALUES
('lockpick', 'Lockpick', 3, 0, 1)
;
INSERT INTO `shops` (`store`, `item`, `price`) VALUES
('TwentyFourSeven', 'lockpick', 10000),
('LTDgasoline', 'lockpick', 10000),
('RobsLiquor', 'lockpick', 10000)
;
