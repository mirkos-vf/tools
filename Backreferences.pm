package RegexStuff;

use strict;
use warnings;
use overload;

sub import { overload::constant('qr' => \&MungeRegexLiteral) }
my $NestedStuffRegex; # Переменная используется в собственном
# определении. Поэтому она должна определяться заранее.
$NestedStuffRegex = qr{
    (?>
        (?: # Не круглые скобки, не '#' и не '\' ...
        [^()\#\\]+
        # Экранирование...
        | (?s: \\. )
        # Комментарии в регулярном выражении...
        | \#.*\n
        # Круглые скобки, внутри которых могут находиться
        # другие вложенные конструкции...
        | \( (??{ $NestedStuffRegex }) \)
        )*
        )
    }x;

sub SimpleConvert; # Функция вызывается рекурсивно, поэтому
# ее необходимо объявить заранее
sub SimpleConvert
{
    my $re = shift; # Регулярное выражение для обработки
    $re =~ s{
        \(\?                    # "(?"
            < ( (?>\w+) ) >     # <$1 > $1-идентификатор
            ($NestedStuffRegex) # $2-вложенные конструкции
            \)                  # ")"
        }{
        my $id = $1;
        my $guts = SimpleConvert($2);
        "(?:($guts)(?{ local(\$^T{'$id'}) = \$^N }))"
        }xeog;
    return $re; # Вернуть обработанное регулярное выражение
}

sub MungeRegexLiteral
{
    my ($RegexLiteral) = @_; # Аргумент-строка
    print "BEFORE: $RegexLiteral\n"; # Снять комментарий при отладке
    my $new = SimpleConvert($RegexLiteral);
    if ($new ne $RegexLiteral)
    {
        my $before = q/(?{ local(%^T) = () })/; # Локализация
        # временного хеша
        my $after = q/(?{ %^N = %^T })/;        # Копирование временного
        # хеша в "настоящий"
        $RegexLiteral = "$before(?:$new)$after";
    }
    print "AFTER: $RegexLiteral\n"; # Снять комментарий при отладке
    return $RegexLiteral;
}

1;