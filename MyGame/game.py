import pygame
import random
import sys

# === ИНИЦИАЛИЗАЦИЯ PYGAME ===
pygame.init()
screen = pygame.display.set_mode((1000, 700))
clock = pygame.time.Clock()

# === КОНСТАНТЫ ===
PLAYER_SPEED = 3
PLAYER_BASE_HP = 100
PLAYER_BASE_ATTACK = 10
PLAYER_BASE_DEFENSE = 5

# Цвета для редкости предметов
RARITY_COLORS = {
    "Common": (200, 200, 200),   # Серый
    "Uncommon": (0, 255, 0),     # Зеленый
    "Rare": (0, 0, 255),         # Синий
    "Epic": (128, 0, 128),       # Фиолетовый
    "Legendary": (255, 165, 0)   # Оранжевый
}

# Списки возможных модификаторов
AFFIX_POOL = {
    "weapon": [
        {"name": "+10% урона", "type": "percent", "stat": "attack", "value": 0.1},
        {"name": "Кража жизни 5%", "type": "percent", "stat": "lifesteal", "value": 0.05},
        {"name": "Скорость атаки +15%", "type": "percent", "stat": "attack_speed", "value": 0.15}
    ],
    "armor": [
        {"name": "+10% здоровья", "type": "percent", "stat": "hp", "value": 0.1},
        {"name": "+10% защиты", "type": "percent", "stat": "defense", "value": 0.1},
    ],
    "helmet": [
        {"name": "+8% здоровья", "type": "percent", "stat": "hp", "value": 0.08},
        {"name": "+10% к опыту", "type": "percent", "stat": "exp_bonus", "value": 0.1}
    ]
}

# Шансы дропа по редкости
RARITY_CHANCES = {
    1: {"Common": 0.7, "Uncommon": 0.25, "Rare": 0.05, "Epic": 0.0, "Legendary": 0.0},
    2: {"Common": 0.6, "Uncommon": 0.3, "Rare": 0.08, "Epic": 0.02, "Legendary": 0.0},
    3: {"Common": 0.5, "Uncommon": 0.3, "Rare": 0.12, "Epic": 0.06, "Legendary": 0.02},
    4: {"Common": 0.4, "Uncommon": 0.3, "Rare": 0.15, "Epic": 0.1, "Legendary": 0.05},
    5: {"Common": 0.3, "Uncommon": 0.3, "Rare": 0.2, "Epic": 0.15, "Legendary": 0.05}
}

# === КЛАССЫ ===

class Player:
    def __init__(self):
        self.reset_position()
        
        # Базовые характеристики
        self.level = 1
        self.exp = 0
        self.exp_to_next_level = 100
        self.base_hp = PLAYER_BASE_HP
        self.base_attack = PLAYER_BASE_ATTACK
        self.base_defense = PLAYER_BASE_DEFENSE
        
        # Итоговые характеристики
        self.max_hp = self.base_hp
        self.hp = self.max_hp
        self.attack = self.base_attack
        self.defense = self.base_defense
        self.lifesteal = 0
        self.attack_speed = 1.0
        self.last_attack_time = 0
        self.exp_bonus = 0
        
        self.equipment = {
            "weapon": None,
            "helmet": None, 
            "armor": None
        }
        self.inventory = []
        self.facing_right = True

    def reset_position(self):
        self.x = 100
        self.y = 500
        self.width = 40
        self.height = 60

    def draw(self, surface):
        # Рисуем игрока
        color = (0, 100, 255)
        pygame.draw.rect(surface, color, (self.x, self.y, self.width, self.height))
        
        # Голова
        head_color = (200, 150, 100)
        pygame.draw.rect(surface, head_color, (self.x + 10, self.y - 15, 20, 20))
        
        # Полоска здоровья
        health_width = (self.hp / self.max_hp) * self.width
        pygame.draw.rect(surface, (255, 0, 0), (self.x, self.y - 25, self.width, 5))
        pygame.draw.rect(surface, (0, 255, 0), (self.x, self.y - 25, health_width, 5))

    def move_right(self):
        self.x += PLAYER_SPEED
        self.facing_right = True

    def can_attack(self, current_time):
        return current_time - self.last_attack_time >= 1000 / self.attack_speed

    def attack_monster(self, monster, current_time):
        if self.can_attack(current_time):
            damage = max(1, self.attack - monster.defense // 2)
            monster.hp -= damage
            self.last_attack_time = current_time
            
            # Кража жизни
            if self.lifesteal > 0:
                heal_amount = int(damage * self.lifesteal)
                self.hp = min(self.max_hp, self.hp + heal_amount)
            
            return damage
        return 0

    def add_exp(self, amount):
        bonus_amount = int(amount * (1 + self.exp_bonus))
        self.exp += bonus_amount
        if self.exp >= self.exp_to_next_level:
            self.level_up()

    def level_up(self):
        self.level += 1
        self.exp = 0
        self.exp_to_next_level = int(self.exp_to_next_level * 1.5)
        
        # Увеличение базовых характеристик
        self.base_hp += 20
        self.base_attack += 5
        self.base_defense += 2
        
        self.recalculate_stats()
        self.hp = self.max_hp

    def equip_item(self, item):
        if item not in self.inventory:
            self.inventory.append(item)
        
        old_item = self.equipment.get(item.item_type)
        self.equipment[item.item_type] = item
        self.recalculate_stats()
        return old_item

    def unequip_item(self, item_type):
        item = self.equipment.get(item_type)
        if item:
            self.equipment[item_type] = None
            self.recalculate_stats()
        return item

    def recalculate_stats(self):
        # Сбрасываем к базовым
        self.max_hp = self.base_hp
        self.attack = self.base_attack
        self.defense = self.base_defense
        self.lifesteal = 0
        self.attack_speed = 1.0
        self.exp_bonus = 0

        # Добавляем бонусы от экипировки
        for item in self.equipment.values():
            if item:
                self.max_hp += item.hp_bonus
                self.attack += item.attack_bonus
                self.defense += item.defense_bonus
                self.lifesteal += item.lifesteal
                self.attack_speed += item.attack_speed
                self.exp_bonus += item.exp_bonus
                
                # Применяем модификаторы
                for affix in item.affixes:
                    if affix["type"] == "percent":
                        if affix["stat"] == "hp":
                            self.max_hp = int(self.max_hp * (1 + affix["value"]))
                        elif affix["stat"] == "attack":
                            self.attack = int(self.attack * (1 + affix["value"]))
                        elif affix["stat"] == "defense":
                            self.defense = int(self.defense * (1 + affix["value"]))
                        elif affix["stat"] == "lifesteal":
                            self.lifesteal += affix["value"]
                        elif affix["stat"] == "attack_speed":
                            self.attack_speed += affix["value"]
                        elif affix["stat"] == "exp_bonus":
                            self.exp_bonus += affix["value"]
        
        # Гарантируем минимальные значения
        self.attack = max(1, self.attack)
        self.defense = max(0, self.defense)
        self.max_hp = max(1, self.max_hp)
        self.attack_speed = max(0.5, self.attack_speed)
        
        if self.hp > self.max_hp:
            self.hp = self.max_hp

    def destroy_item(self, item):
        if item in self.inventory:
            self.inventory.remove(item)
            # Если предмет был экипирован - снимаем его
            for slot_type, equipped_item in self.equipment.items():
                if equipped_item == item:
                    self.equipment[slot_type] = None
            self.recalculate_stats()
            return True
        return False

    def destroy_items_by_filter(self, item_type_filter=None, rarity_filter=None):
        destroyed = []
        for item in self.inventory[:]:
            if item_type_filter and item.item_type != item_type_filter:
                continue
            if rarity_filter and item.rarity != rarity_filter:
                continue
            if self.destroy_item(item):
                destroyed.append(item)
        return destroyed

    def sort_inventory(self, sort_by="rarity"):
        """Сортировка инвентаря"""
        if sort_by == "rarity":
            rarity_order = {"Common": 0, "Uncommon": 1, "Rare": 2, "Epic": 3, "Legendary": 4}
            self.inventory.sort(key=lambda x: rarity_order.get(x.rarity, 0), reverse=True)
        elif sort_by == "type":
            type_order = {"weapon": 0, "helmet": 1, "armor": 2}
            self.inventory.sort(key=lambda x: type_order.get(x.item_type, 0))
        elif sort_by == "level":
            # Для будущей системы уровней предметов
            self.inventory.sort(key=lambda x: x.attack_bonus + x.defense_bonus, reverse=True)

class Item:
    def __init__(self, item_type, floor_level):
        self.item_type = item_type
        self.rarity = self.generate_rarity(floor_level)
        self.attack_bonus = 0
        self.defense_bonus = 0
        self.hp_bonus = 0
        self.lifesteal = 0
        self.attack_speed = 0
        self.exp_bonus = 0
        self.affixes = []

        self.generate_base_stats()
        self.generate_affixes()
        
        self.name = f"{self.rarity} {item_type}"
        self.icon = self.get_icon()

    def get_icon(self):
        """Создаем простую иконку вместо эмодзи"""
        if self.item_type == "weapon":
            return "W"  # Weapon
        elif self.item_type == "helmet":
            return "H"  # Helmet
        elif self.item_type == "armor":
            return "A"  # Armor
        return "?"

    def generate_rarity(self, floor_level):
        floor_chances = RARITY_CHANCES.get(min(floor_level, 5), RARITY_CHANCES[5])
        rand = random.random()
        cumulative = 0
        
        for rarity, chance in floor_chances.items():
            cumulative += chance
            if rand <= cumulative:
                return rarity
        return "Common"

    def generate_base_stats(self):
        rarity_multiplier = list(RARITY_COLORS.keys()).index(self.rarity) + 1
        
        if self.item_type == "weapon":
            self.attack_bonus = random.randint(3, 8) * rarity_multiplier
            self.attack_speed = 0.1 * rarity_multiplier
        elif self.item_type == "armor":
            self.defense_bonus = random.randint(2, 5) * rarity_multiplier
            self.hp_bonus = random.randint(10, 25) * rarity_multiplier
        elif self.item_type == "helmet":
            self.defense_bonus = random.randint(1, 3) * rarity_multiplier
            self.hp_bonus = random.randint(5, 15) * rarity_multiplier

    def generate_affixes(self):
        num_affixes = list(RARITY_COLORS.keys()).index(self.rarity)
        used_affix_names = set()
        
        available_affixes = AFFIX_POOL.get(self.item_type, [])
        for _ in range(num_affixes):
            if not available_affixes:
                break
                
            possible_affixes = [a for a in available_affixes if a["name"] not in used_affix_names]
            if not possible_affixes:
                break
                
            affix = random.choice(possible_affixes)
            self.affixes.append(affix.copy())
            used_affix_names.add(affix["name"])
            
            # Немедленно применяем бонусы
            if affix["type"] == "percent":
                if affix["stat"] == "hp":
                    self.hp_bonus = int(self.hp_bonus * (1 + affix["value"]))
                elif affix["stat"] == "attack":
                    self.attack_bonus = int(self.attack_bonus * (1 + affix["value"]))
                elif affix["stat"] == "defense":
                    self.defense_bonus = int(self.defense_bonus * (1 + affix["value"]))
                elif affix["stat"] == "lifesteal":
                    self.lifesteal += affix["value"]
                elif affix["stat"] == "attack_speed":
                    self.attack_speed += affix["value"]
                elif affix["stat"] == "exp_bonus":
                    self.exp_bonus += affix["value"]

    def get_color(self):
        return RARITY_COLORS.get(self.rarity, (255, 255, 255))

class Monster:
    def __init__(self, floor_level):
        self.x = 800
        self.y = 500
        self.width = 35
        self.height = 50
        self.level = max(1, floor_level)
        
        # Характеристики
        self.max_hp = 40 + (floor_level * 10)
        self.hp = self.max_hp
        self.attack_damage = 5 + floor_level
        self.defense = floor_level
        self.exp_value = 20 + floor_level * 5
        self.attack_speed = 1.0
        self.last_attack_time = 0
        
        color_intensity = min(255, 100 + floor_level * 20)
        self.color = (color_intensity, 0, 0)

    def draw(self, surface):
        # Тело монстра
        pygame.draw.rect(surface, self.color, (self.x, self.y, self.width, self.height))
        
        # Голова
        head_color = (150, 0, 0)
        pygame.draw.rect(surface, head_color, (self.x + 5, self.y - 15, 25, 20))
        
        # Полоска здоровья
        health_width = (self.hp / self.max_hp) * self.width
        pygame.draw.rect(surface, (255, 0, 0), (self.x, self.y - 25, self.width, 5))
        pygame.draw.rect(surface, (0, 255, 0), (self.x, self.y - 25, health_width, 5))
        
        # Уровень монстра
        font = pygame.font.SysFont(None, 20)
        level_text = font.render(str(self.level), True, (255, 255, 255))
        surface.blit(level_text, (self.x + 12, self.y - 12))

    def move_towards_player(self, player_x):
        if self.x > player_x + 60:
            self.x -= 2
        elif self.x < player_x - 60:
            self.x += 2

    def can_attack(self, current_time):
        return current_time - self.last_attack_time >= 1000 / self.attack_speed

    def attack_player(self, player, current_time):
        if self.can_attack(current_time):
            damage = max(1, self.attack_damage - player.defense // 3)
            player.hp -= damage
            self.last_attack_time = current_time
            return damage
        return 0

class InventorySystem:
    def __init__(self):
        self.visible = False
        self.selected_item = None
        self.scroll_offset = 0
        self.item_type_filter = None
        self.rarity_filter = None
        self.confirm_delete_all = False
        
    def draw(self, surface, player):
        if not self.visible:
            return
            
        # Фон инвентаря
        inventory_rect = pygame.Rect(100, 50, 800, 600)
        pygame.draw.rect(surface, (40, 40, 40), inventory_rect)
        pygame.draw.rect(surface, (100, 100, 100), inventory_rect, 3)
        
        font = pygame.font.SysFont(None, 24)
        title_font = pygame.font.SysFont(None, 28)
        
        title = title_font.render("ИНВЕНТАРЬ (I - закрыть)", True, (255, 255, 255))
        surface.blit(title, (inventory_rect.x + 10, inventory_rect.y + 10))
        
        # Разделительная линия
        pygame.draw.line(surface, (100, 100, 100), (inventory_rect.x + 400, inventory_rect.y + 50), 
                         (inventory_rect.x + 400, inventory_rect.y + 550), 2)
        
        # Левая часть - экипировка и характеристики
        self.draw_equipment_and_stats(surface, inventory_rect.x + 20, inventory_rect.y + 60, player)
        
        # Правая часть - инвентарь и фильтры
        self.draw_inventory_with_filters(surface, inventory_rect.x + 420, inventory_rect.y + 60, player)
        
        # Описание выбранного предмета внизу
        if self.selected_item:
            self.draw_item_comparison(surface, inventory_rect.x + 20, inventory_rect.y + 450, player)

        # Подтверждение удаления всех предметов
        if self.confirm_delete_all:
            self.draw_confirmation_dialog(surface, player)

    def draw_equipment_and_stats(self, surface, x, y, player):
        font = pygame.font.SysFont(None, 24)
        title_font = pygame.font.SysFont(None, 26)
        
        # Заголовок
        equip_title = title_font.render("ЭКИПИРОВКА И ХАРАКТЕРИСТИКИ", True, (255, 255, 0))
        surface.blit(equip_title, (x, y))
        
        # Слоты экипировки
        slots = [
            ("weapon", "Оружие", x + 20, y + 40),
            ("helmet", "Шлем", x + 20, y + 120),
            ("armor", "Броня", x + 20, y + 200)
        ]
        
        for slot_type, slot_name, slot_x, slot_y in slots:
            # Рамка слота
            slot_rect = pygame.Rect(slot_x, slot_y, 80, 80)
            slot_color = (80, 80, 80)
            if self.selected_item and self.selected_item.item_type == slot_type:
                slot_color = (120, 120, 0)
                
            pygame.draw.rect(surface, slot_color, slot_rect)
            pygame.draw.rect(surface, (200, 200, 200), slot_rect, 2)
            
            # Название слота
            name_text = font.render(slot_name, True, (255, 255, 255))
            surface.blit(name_text, (slot_x, slot_y - 25))
            
            # Предмет в слоте
            equipped_item = player.equipment.get(slot_type)
            if equipped_item:
                # Иконка предмета
                item_color = equipped_item.get_color()
                pygame.draw.rect(surface, item_color, (slot_x + 10, slot_y + 10, 60, 60))
                
                # Иконка типа предмета
                icon_font = pygame.font.SysFont(None, 40)
                icon_text = icon_font.render(equipped_item.icon, True, (255, 255, 255))
                surface.blit(icon_text, (slot_x + 30, slot_y + 20))
                
                # Кнопка "Снять"
                unequip_rect = pygame.Rect(slot_x, slot_y + 85, 80, 25)
                pygame.draw.rect(surface, (150, 0, 0), unequip_rect)
                unequip_text = font.render("Снять", True, (255, 255, 255))
                surface.blit(unequip_text, (unequip_rect.x + 20, unequip_rect.y + 5))
        
        # Характеристики персонажа
        stats_x = x + 120
        stats_y = y + 40
        stats_title = font.render("ХАРАКТЕРИСТИКИ:", True, (0, 255, 255))
        surface.blit(stats_title, (stats_x, stats_y))
        
        stats = [
            f"Уровень: {player.level}",
            f"HP: {player.hp}/{player.max_hp}",
            f"Атака: {player.attack}",
            f"Защита: {player.defense}",
            f"Кража жизни: {player.lifesteal*100:.1f}%",
            f"Скорость атаки: {player.attack_speed:.1f}/сек",
            f"Бонус опыта: {player.exp_bonus*100:.1f}%"
        ]
        
        for i, stat in enumerate(stats):
            stat_text = font.render(stat, True, (255, 255, 255))
            surface.blit(stat_text, (stats_x, stats_y + 30 + i * 25))

    def draw_inventory_with_filters(self, surface, x, y, player):
        font = pygame.font.SysFont(None, 24)
        title_font = pygame.font.SysFont(None, 26)
        
        # Заголовок
        items_title = title_font.render("ИНВЕНТАРЬ", True, (255, 255, 0))
        surface.blit(items_title, (x, y))
        
        # Фильтры
        self.draw_filters(surface, x, y + 30, font)
        
        # Кнопки сортировки
        self.draw_sort_buttons(surface, x, y + 70, font, player)
        
        # Сетка предметов с скроллингом
        filtered_items = self.get_filtered_items(player.inventory)
        self.draw_inventory_grid(surface, x, y + 110, filtered_items, player, font)
        
        # Кнопки массового удаления
        self.draw_bulk_delete_buttons(surface, x, y + 430, font, player)

    def draw_filters(self, surface, x, y, font):
        # Фильтр по типу
        type_filters = [None, "weapon", "helmet", "armor"]
        type_names = ["Все", "Оружие", "Шлемы", "Броня"]
        
        type_label = font.render("Тип:", True, (255, 255, 255))
        surface.blit(type_label, (x, y))
        
        for i, (filter_type, name) in enumerate(zip(type_filters, type_names)):
            btn_rect = pygame.Rect(x + 50 + i * 85, y, 80, 25)
            color = (0, 100, 200) if self.item_type_filter == filter_type else (70, 70, 70)
            pygame.draw.rect(surface, color, btn_rect)
            text = font.render(name, True, (255, 255, 255))
            text_rect = text.get_rect(center=btn_rect.center)
            surface.blit(text, text_rect)
        
        # Фильтр по редкости
        rarity_filters = [None, "Common", "Uncommon", "Rare", "Epic", "Legendary"]
        rarity_names = ["Все", "Обычн.", "Необыч.", "Редкие", "Эпич.", "Легенд."]
        
        rarity_label = font.render("Редкость:", True, (255, 255, 255))
        surface.blit(rarity_label, (x, y + 35))
        
        for i, (filter_rarity, name) in enumerate(zip(rarity_filters, rarity_names)):
            btn_rect = pygame.Rect(x + 80 + i * 65, y + 35, 60, 25)
            color = RARITY_COLORS.get(filter_rarity, (70, 70, 70)) 
            if self.rarity_filter == filter_rarity:
                color = tuple(min(c + 50, 255) for c in color)  # Делаем ярче
            else:
                color = tuple(max(c - 30, 40) for c in color)  # Делаем темнее
                
            pygame.draw.rect(surface, color, btn_rect)
            text = font.render(name, True, (255, 255, 255))
            text_rect = text.get_rect(center=btn_rect.center)
            surface.blit(text, text_rect)

    def draw_sort_buttons(self, surface, x, y, font, player):
        sort_label = font.render("Сортировка:", True, (255, 255, 255))
        surface.blit(sort_label, (x, y))
        
        sort_buttons = [
            ("По редкости", "rarity", x + 100, y),
            ("По типу", "type", x + 220, y),
        ]
        
        for text, sort_type, btn_x, btn_y in sort_buttons:
            btn_rect = pygame.Rect(btn_x, btn_y, 110, 25)
            pygame.draw.rect(surface, (80, 80, 120), btn_rect)
            btn_text = font.render(text, True, (255, 255, 255))
            text_rect = btn_text.get_rect(center=btn_rect.center)
            surface.blit(btn_text, text_rect)

    def draw_inventory_grid(self, surface, x, y, items, player, font):
        # Отображаем 12 предметов (3x4) с учетом скролла
        for i in range(12):
            item_index = i + self.scroll_offset
            if item_index >= len(items):
                # Пустая ячейка
                item_x = x + (i % 3) * 100
                item_y = y + (i // 3) * 100
                empty_rect = pygame.Rect(item_x, item_y, 80, 80)
                pygame.draw.rect(surface, (50, 50, 50), empty_rect)
                pygame.draw.rect(surface, (100, 100, 100), empty_rect, 2)
                continue
                
            item = items[item_index]
            item_x = x + (i % 3) * 100
            item_y = y + (i // 3) * 100
            
            # Ячейка предмета
            item_rect = pygame.Rect(item_x, item_y, 80, 80)
            item_color = item.get_color()
            
            # Подсветка выбранного предмета
            if item == self.selected_item:
                pygame.draw.rect(surface, (150, 150, 0), item_rect)
            else:
                pygame.draw.rect(surface, (70, 70, 70), item_rect)
                
            # Иконка предмета
            pygame.draw.rect(surface, item_color, (item_x + 10, item_y + 10, 60, 60))
            
            # Иконка типа предмета
            icon_font = pygame.font.SysFont(None, 40)
            icon_text = icon_font.render(item.icon, True, (255, 255, 255))
            surface.blit(icon_text, (item_x + 35, item_y + 25))
            
            pygame.draw.rect(surface, (200, 200, 200), item_rect, 2)
            
            # Кнопки действий
            equip_rect = pygame.Rect(item_x, item_y + 85, 40, 20)
            destroy_rect = pygame.Rect(item_x + 42, item_y + 85, 38, 20)
            
            # Кнопка "Надеть"
            equip_color = (0, 150, 0) if item != player.equipment.get(item.item_type) else (100, 100, 100)
            pygame.draw.rect(surface, equip_color, equip_rect)
            equip_text = font.render("Над", True, (255, 255, 255))
            surface.blit(equip_text, (equip_rect.x + 8, equip_rect.y + 2))
            
            # Кнопка "Удалить"
            pygame.draw.rect(surface, (150, 0, 0), destroy_rect)
            destroy_text = font.render("Удал", True, (255, 255, 255))
            surface.blit(destroy_text, (destroy_rect.x + 5, destroy_rect.y + 2))
        
        # Стрелки скролла если нужно
        if len(items) > 12:
            scroll_x = x + 250
            if self.scroll_offset > 0:
                up_rect = pygame.Rect(scroll_x, y - 30, 30, 20)
                pygame.draw.rect(surface, (100, 100, 100), up_rect)
                up_text = font.render("↑", True, (255, 255, 255))
                surface.blit(up_text, (up_rect.x + 10, up_rect.y + 2))
            
            if self.scroll_offset < len(items) - 12:
                down_rect = pygame.Rect(scroll_x, y + 320, 30, 20)
                pygame.draw.rect(surface, (100, 100, 100), down_rect)
                down_text = font.render("↓", True, (255, 255, 255))
                surface.blit(down_text, (down_rect.x + 10, down_rect.y + 2))

    def draw_bulk_delete_buttons(self, surface, x, y, font, player):
        bulk_title = font.render("Массовое удаление:", True, (255, 100, 100))
        surface.blit(bulk_title, (x, y))
        
        buttons = [
            ("Все обычные", "Common", x, y + 30),
            ("Все необычные", "Uncommon", x + 120, y + 30),
            ("Все редкие", "Rare", x + 240, y + 30),
            ("Все эпические", "Epic", x, y + 60),
            ("Все легендарные", "Legendary", x + 120, y + 60),
            ("ВСЕ ПРЕДМЕТЫ", "ALL", x + 240, y + 60)
        ]
        
        for text, rarity, btn_x, btn_y in buttons:
            btn_rect = pygame.Rect(btn_x, btn_y, 115, 25)
            color = (150, 0, 0) if rarity != "ALL" else (200, 0, 0)
            pygame.draw.rect(surface, color, btn_rect)
            btn_font = pygame.font.SysFont(None, 18)
            btn_text = btn_font.render(text, True, (255, 255, 255))
            text_rect = btn_text.get_rect(center=btn_rect.center)
            surface.blit(btn_text, text_rect)

    def draw_item_comparison(self, surface, x, y, player):
        info_rect = pygame.Rect(x, y, 760, 140)
        pygame.draw.rect(surface, (30, 30, 30), info_rect)
        pygame.draw.rect(surface, (100, 100, 100), info_rect, 2)
        
        font = pygame.font.SysFont(None, 22)
        title_font = pygame.font.SysFont(None, 24)
        
        # Заголовок с именем и иконкой
        title_text = f"{self.selected_item.icon} {self.selected_item.name}"
        title = title_font.render(title_text, True, self.selected_item.get_color())
        surface.blit(title, (info_rect.x + 10, info_rect.y + 10))
        
        # Текущий экипированный предмет того же типа
        current_item = player.equipment.get(self.selected_item.item_type)
        
        # Статистика выбранного предмета
        selected_stats = self.get_item_stats(self.selected_item)
        current_stats = self.get_item_stats(current_item) if current_item else []
        
        # Отображаем сравнение
        stats_y = info_rect.y + 40
        for i, (stat_name, selected_value) in enumerate(selected_stats):
            current_value = next((val for name, val in current_stats if name == stat_name), 0)
            
            # Сравниваем значения
            if isinstance(selected_value, str):
                # Для строковых значений (проценты)
                selected_num = float(selected_value.replace('+', '').replace('%', ''))
                current_num = float(current_value.replace('+', '').replace('%', '')) if current_value else 0
            else:
                selected_num = selected_value
                current_num = current_value
            
            # Цвет и стрелка в зависимости от сравнения
            color = (255, 255, 255)
            arrow = ""
            if selected_num > current_num:
                color = (0, 255, 0)  # Зеленый - лучше
                arrow = " ↑"
            elif selected_num < current_num:
                color = (255, 0, 0)  # Красный - хуже
                arrow = " ↓"
            
            stat_text = font.render(f"{stat_name}: {selected_value}{arrow}", True, color)
            surface.blit(stat_text, (info_rect.x + 10 + (i % 3) * 250, stats_y + (i // 3) * 20))
        
        # Модификаторы
        if self.selected_item.affixes:
            mod_y = info_rect.y + 100
            mod_title = font.render("Модификаторы:", True, (200, 200, 0))
            surface.blit(mod_title, (info_rect.x + 10, mod_y))
            
            for i, affix in enumerate(self.selected_item.affixes):
                affix_text = font.render(affix["name"], True, (200, 200, 100))
                surface.blit(affix_text, (info_rect.x + 120 + i * 200, mod_y))

    def draw_confirmation_dialog(self, surface, player):
        """Диалог подтверждения удаления всех предметов"""
        dialog_rect = pygame.Rect(300, 250, 400, 150)
        pygame.draw.rect(surface, (60, 60, 80), dialog_rect)
        pygame.draw.rect(surface, (100, 100, 120), dialog_rect, 3)
        
        font = pygame.font.SysFont(None, 24)
        
        warning = font.render("УДАЛИТЬ ВСЕ ПРЕДМЕТЫ?", True, (255, 100, 100))
        surface.blit(warning, (dialog_rect.centerx - warning.get_width()//2, dialog_rect.y + 20))
        
        count_text = font.render(f"Будет удалено: {len(player.inventory)} предметов", True, (255, 255, 255))
        surface.blit(count_text, (dialog_rect.centerx - count_text.get_width()//2, dialog_rect.y + 50))
        
        # Кнопки подтверждения
        yes_rect = pygame.Rect(dialog_rect.x + 80, dialog_rect.y + 90, 100, 35)
        no_rect = pygame.Rect(dialog_rect.x + 220, dialog_rect.y + 90, 100, 35)
        
        pygame.draw.rect(surface, (200, 0, 0), yes_rect)
        pygame.draw.rect(surface, (0, 150, 0), no_rect)
        
        yes_text = font.render("ДА", True, (255, 255, 255))
        no_text = font.render("ОТМЕНА", True, (255, 255, 255))
        
        surface.blit(yes_text, (yes_rect.centerx - yes_text.get_width()//2, yes_rect.centery - yes_text.get_height()//2))
        surface.blit(no_text, (no_rect.centerx - no_text.get_width()//2, no_rect.centery - no_text.get_height()//2))

    def get_item_stats(self, item):
        if not item:
            return []
        stats = []
        if item.attack_bonus > 0:
            stats.append(("Атака", item.attack_bonus))
        if item.defense_bonus > 0:
            stats.append(("Защита", item.defense_bonus))
        if item.hp_bonus > 0:
            stats.append(("HP", item.hp_bonus))
        if item.attack_speed > 0:
            stats.append(("Скор. атаки", f"+{item.attack_speed:.1f}"))
        if item.lifesteal > 0:
            stats.append(("Кража жизни", f"{item.lifesteal*100:.1f}%"))
        if item.exp_bonus > 0:
            stats.append(("Бонус опыта", f"{item.exp_bonus*100:.1f}%"))
        return stats

    def get_filtered_items(self, inventory):
        filtered = inventory
        if self.item_type_filter:
            filtered = [item for item in filtered if item.item_type == self.item_type_filter]
        if self.rarity_filter:
            filtered = [item for item in filtered if item.rarity == self.rarity_filter]
        return filtered

    def handle_click(self, pos, player):
        if not self.visible:
            return False
            
        # Обработка подтверждения удаления
        if self.confirm_delete_all:
            return self.handle_confirmation_click(pos, player)
            
        inventory_rect = pygame.Rect(100, 50, 800, 600)
        if not inventory_rect.collidepoint(pos):
            return False

        # Определяем область клика
        x, y = pos
        
        # Левая часть (экипировка и характеристики)
        if x < 500:
            return self.handle_left_panel_click(pos, player)
        # Правая часть (инвентарь)
        else:
            return self.handle_right_panel_click(pos, player)

    def handle_left_panel_click(self, pos, player):
        x, y = pos
        
        # Клики по слотам экипировки (120, 110) - (200, 290)
        slots = [
            ("weapon", 140, 150),
            ("helmet", 140, 230), 
            ("armor", 140, 310)
        ]
        
        for slot_type, slot_x, slot_y in slots:
            slot_rect = pygame.Rect(slot_x, slot_y, 80, 80)
            unequip_rect = pygame.Rect(slot_x, slot_y + 85, 80, 25)
            
            if slot_rect.collidepoint(pos):
                equipped_item = player.equipment.get(slot_type)
                if equipped_item:
                    self.selected_item = equipped_item
                return True
                
            if unequip_rect.collidepoint(pos):
                player.unequip_item(slot_type)
                return True
                
        return False

    def handle_right_panel_click(self, pos, player):
        x, y = pos
        
        # Фильтры по типу (420, 90)
        type_filters = [None, "weapon", "helmet", "armor"]
        for i in range(4):
            btn_rect = pygame.Rect(470 + i * 85, 90, 80, 25)
            if btn_rect.collidepoint(pos):
                self.item_type_filter = type_filters[i]
                self.scroll_offset = 0
                return True
                
        # Фильтры по редкости (420, 125)
        rarity_filters = [None, "Common", "Uncommon", "Rare", "Epic", "Legendary"]
        for i in range(6):
            btn_rect = pygame.Rect(500 + i * 65, 125, 60, 25)
            if btn_rect.collidepoint(pos):
                self.rarity_filter = rarity_filters[i]
                self.scroll_offset = 0
                return True
        
        # Кнопки сортировки
        sort_buttons = [
            ("rarity", 520, 160),
            ("type", 640, 160),
        ]
        
        for sort_type, btn_x, btn_y in sort_buttons:
            btn_rect = pygame.Rect(btn_x, btn_y, 110, 25)
            if btn_rect.collidepoint(pos):
                player.sort_inventory(sort_type)
                return True
        
        # Скролл
        filtered_items = self.get_filtered_items(player.inventory)
        scroll_x = 670
        
        if self.scroll_offset > 0:
            up_rect = pygame.Rect(scroll_x, 80, 30, 20)
            if up_rect.collidepoint(pos):
                self.scroll_offset -= 1
                return True
                
        if self.scroll_offset < len(filtered_items) - 12:
            down_rect = pygame.Rect(scroll_x, 430, 30, 20)
            if down_rect.collidepoint(pos):
                self.scroll_offset += 1
                return True
        
        # Предметы в инвентаре
        for i in range(12):
            item_index = i + self.scroll_offset
            if item_index >= len(filtered_items):
                continue
                
            item_x = 420 + (i % 3) * 100
            item_y = 210 + (i // 3) * 100
            
            item_rect = pygame.Rect(item_x, item_y, 80, 80)
            equip_rect = pygame.Rect(item_x, item_y + 85, 40, 20)
            destroy_rect = pygame.Rect(item_x + 42, item_y + 85, 38, 20)
            
            if item_rect.collidepoint(pos):
                self.selected_item = filtered_items[item_index]
                return True
                
            if equip_rect.collidepoint(pos):
                if filtered_items[item_index] != player.equipment.get(filtered_items[item_index].item_type):
                    player.equip_item(filtered_items[item_index])
                return True
                
            if destroy_rect.collidepoint(pos):
                player.destroy_item(filtered_items[item_index])
                if self.selected_item == filtered_items[item_index]:
                    self.selected_item = None
                return True
        
        # Массовое удаление
        bulk_buttons = [
            ("Common", 420, 540),
            ("Uncommon", 540, 540),
            ("Rare", 660, 540),
            ("Epic", 420, 570),
            ("Legendary", 540, 570),
            ("ALL", 660, 570)
        ]
        
        for rarity, btn_x, btn_y in bulk_buttons:
            btn_rect = pygame.Rect(btn_x, btn_y, 115, 25)
            if btn_rect.collidepoint(pos):
                if rarity == "ALL":
                    self.confirm_delete_all = True
                else:
                    player.destroy_items_by_filter(None, rarity)
                return True
                
        return False

    def handle_confirmation_click(self, pos, player):
        yes_rect = pygame.Rect(380, 340, 100, 35)
        no_rect = pygame.Rect(520, 340, 100, 35)
        
        if yes_rect.collidepoint(pos):
            # Удаляем все предметы
            for item in player.inventory[:]:
                player.destroy_item(item)
            self.confirm_delete_all = False
            self.selected_item = None
            return True
        elif no_rect.collidepoint(pos):
            self.confirm_delete_all = False
            return True
            
        return False

# === ОСНОВНОЙ ЦИКЛ ИГРЫ ===
def main():
    player = Player()
    inventory_system = InventorySystem()
    
    killed_monsters = 0
    current_floor = 1
    game_state = "playing"
    current_monster = None
    
    # Сохраняем прогресс между смертями
    saved_inventory = []
    saved_equipment = {"weapon": None, "helmet": None, "armor": None}
    saved_level = 1
    saved_exp = 0
    
    # Создаем землю
    ground_y = 550
    
    font = pygame.font.SysFont(None, 24)
    small_font = pygame.font.SysFont(None, 20)

    running = True
    while running:
        current_time = pygame.time.get_ticks()
        
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_i:
                    inventory_system.visible = not inventory_system.visible
                    inventory_system.confirm_delete_all = False  # Сбрасываем подтверждение при закрытии
                elif event.key == pygame.K_r and game_state == "game_over":
                    # Возрождение с сохранением прогресса
                    player.inventory = saved_inventory.copy()
                    player.equipment = {k: v for k, v in saved_equipment.items()}
                    player.level = saved_level
                    player.exp = saved_exp
                    player.recalculate_stats()
                    player.hp = player.max_hp
                    player.reset_position()
                    killed_monsters = 0
                    current_floor = max(1, current_floor - 1)
                    game_state = "playing"
                    current_monster = None
            elif event.type == pygame.MOUSEBUTTONDOWN:
                if inventory_system.visible:
                    inventory_system.handle_click(event.pos, player)

        if game_state == "playing":
            # Сохраняем прогресс перед каждым боем
            if not current_monster:
                saved_inventory = player.inventory.copy()
                saved_equipment = {k: v for k, v in player.equipment.items()}
                saved_level = player.level
                saved_exp = player.exp

            # Автоматическое движение вправо
            player.move_right()

            # Спавн монстра если его нет и игрок дошел до середины экрана
            if not current_monster and player.x > 400:
                current_monster = Monster(current_floor)
                game_state = "battle"

        elif game_state == "battle":
            if current_monster:
                # Монстр движется к игроку
                current_monster.move_towards_player(player.x)
                
                # Проверка расстояния для атаки
                distance = abs(player.x - current_monster.x)
                if distance <= 80:
                    # Останавливаем игрока
                    if player.x > 300:
                        player.x = 300
                    
                    # Игрок атакует монстра
                    player_damage = player.attack_monster(current_monster, current_time)
                    
                    # Монстр атакует игрока
                    monster_damage = current_monster.attack_player(player, current_time)
                    
                    # Проверка смерти монстра
                    if current_monster.hp <= 0:
                        player.add_exp(current_monster.exp_value)
                        killed_monsters += 1
                        current_monster = None

                        # Переход на новый этаж
                        if killed_monsters >= 3:
                            current_floor += 1
                            killed_monsters = 0
                            player.hp = player.max_hp

                        # Шанс дропа предмета
                        if random.random() < 0.6:
                            item_type = random.choice(["weapon", "helmet", "armor"])
                            new_item = Item(item_type, current_floor)
                            player.inventory.append(new_item)

                        # Сброс позиции
                        player.reset_position()
                        game_state = "playing"

                # Проверка смерти игрока
                if player.hp <= 0:
                    game_state = "game_over"

        # Отрисовка
        screen.fill((100, 100, 255))
        
        # Рисуем землю
        pygame.draw.rect(screen, (100, 70, 30), (0, ground_y, 1000, 150))
        pygame.draw.rect(screen, (0, 150, 0), (0, ground_y, 1000, 10))
        
        # Рисуем монстра если есть
        if current_monster:
            current_monster.draw(screen)

        # Рисуем игрока
        player.draw(screen)

        # Рисуем UI
        hp_text = font.render(f"HP: {player.hp}/{player.max_hp}", True, (255, 255, 255))
        attack_text = font.render(f"ATK: {player.attack}", True, (255, 255, 255))
        defense_text = font.render(f"DEF: {player.defense}", True, (255, 255, 255))
        level_text = font.render(f"Уровень: {player.level}", True, (255, 255, 255))
        exp_text = font.render(f"EXP: {player.exp}/{player.exp_to_next_level}", True, (255, 255, 255))
        floor_text = font.render(f"Этаж: {current_floor}", True, (255, 255, 255))
        kills_text = font.render(f"Убито: {killed_monsters}/3", True, (255, 255, 255))

        screen.blit(hp_text, (10, 10))
        screen.blit(attack_text, (10, 40))
        screen.blit(defense_text, (10, 70))
        screen.blit(level_text, (10, 100))
        screen.blit(exp_text, (10, 130))
        screen.blit(floor_text, (10, 160))
        screen.blit(kills_text, (10, 190))

        # Дополнительная информация
        info_text = small_font.render("I - инвентарь", True, (200, 200, 200))
        screen.blit(info_text, (10, 220))

        # Отображаем состояние игры
        if game_state == "battle":
            state_text = font.render("БОЙ!", True, (255, 0, 0))
            screen.blit(state_text, (800, 20))
        elif game_state == "playing":
            state_text = font.render("ДВИЖЕНИЕ", True, (0, 255, 0))
            screen.blit(state_text, (800, 20))

        # Рисуем инвентарь если открыт
        inventory_system.draw(screen, player)

        # Экран Game Over
        if game_state == "game_over":
            overlay = pygame.Surface((1000, 700), pygame.SRCALPHA)
            overlay.fill((0, 0, 0, 200))
            screen.blit(overlay, (0, 0))
            
            game_over_font = pygame.font.SysFont(None, 48)
            game_over_text = game_over_font.render("ВЫ УМЕРЛИ", True, (255, 0, 0))
            restart_text = font.render("Нажмите R для возрождения на предыдущем этаже", True, (255, 255, 255))
            floor_info = font.render(f"Вы возродитесь на этаже: {max(1, current_floor - 1)}", True, (255, 255, 255))
            progress_info = font.render("Весь ваш инвентарь и прогресс сохранены", True, (255, 255, 255))
            
            screen.blit(game_over_text, (500 - game_over_text.get_width() // 2, 300))
            screen.blit(restart_text, (500 - restart_text.get_width() // 2, 360))
            screen.blit(floor_info, (500 - floor_info.get_width() // 2, 390))
            screen.blit(progress_info, (500 - progress_info.get_width() // 2, 420))

        pygame.display.flip()
        clock.tick(60)

    pygame.quit()
    sys.exit()

if __name__ == "__main__":
    main()