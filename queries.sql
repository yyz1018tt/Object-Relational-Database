/*Q1*/
select a.albumTitle, a.albumReleaseDate, a.albumPrice, artists.artistName
from albums a, table(a.albumArtists) artists
where artists.artistName = 'Neil Young' and a.albumreleasedate > to_date('1-JAN-2015')

/*Q2*/
select a.albumTitle, artists.artistName, treat(value(a) as mp3_type).downloadSize 
from albums a, table(a.albumArtists) artists 
where value(a) is of (mp3_type) order by a.albumTitle

/*Q3*/
select a.albumTitle, avg(reviews.reviewScore)
from albums a, table(a.albumReviews) reviews
where value(a) is of (mp3_type)
group by a.albumTitle
having count(reviews.reviewText) > 1 
and avg(reviews.reviewScore) = (select min(avg(reviews.reviewScore))
                                from albums a, table(a.albumReviews) reviews
                                where value(a) is of (mp3_type)
                                group by a.albumTitle
                                having count(reviews.reviewText) > 1)

/*Q4*/
select a.albumTitle from albums a, albums b, albums c
where value(a) is of (mp3_type)
and treat(value(b) as disk_type).mediaType = 'Vinyl'
and treat(value(c) as disk_type).mediaType = 'Audio CD'
and a.albumTitle = b.albumTitle
and b.albumTitle = c.albumTitle
order by a.albumTitle

/*Q5*/
create or replace type body disk_type 
as overriding member function discountPrice 
return number is discount_price number;
begin
    if albumReleaseDate < add_months(sysdate, -12) then
        case mediaType 
            when 'Audio CD' then
                discount_price := albumPrice - albumPrice * 0.2;
            when 'Vinyl' then
                discount_price := albumPrice - albumPrice * 0.15;
        end case;
    else
        discount_price := albumPrice;
    end if;
    return discount_price;
end;
end;
/
create or replace type body mp3_type 
as overriding member function discountPrice return number is discount_price number;
begin
	if albumReleaseDate < add_months(sysdate, -24) then
		discount_price := albumPrice - albumPrice * 0.1;
    else
        discount_price := albumPrice;
	end if;
	return discount_price;
end;
end;

select a.albumtitle, treat(value(a) as disk_type).mediaType as mediaType, a.discountPrice() as discounted_price 
from albums a where value(a) is of (disk_type)
union all
select b.albumtitle, 'mp3', b.discountPrice() as discounted_price 
from albums b where value(b) is of (mp3_type)

/*Q6*/
create or replace view all_albums as
    select a.albumTitle, treat(value(a) as disk_type).mediaType as mediaType, a.albumPrice, a.albumPrice-a.discountPrice() as discount_price 
    from albums a 
    where value(a) is of (disk_type)
    union all 
    select b.albumTitle, 'mp3', b.albumPrice, b.albumPrice-b.discountPrice() as discount_price from albums b 
    where value(b) is of (mp3_type)
    
select albumTitle, mediaType, albumPrice, discount_price 
from all_albums 
where discount_price = (select max(discount_price) from all_albums)

/*Q7*/
create or replace view all_albums as 
    select a.albumTitle, treat(value(a) as disk_type).mediaType as mediaType, a.albumPrice,
    a.albumPrice-a.discountPrice() as discount_price, treat(value(a) as disk_type).diskUsedPrice as used_price
    from albums a
    where value(a) is of (disk_type)
    union all 
    select b.albumTitle, 'mp3', b.albumPrice, 
    b.albumPrice-b.discountPrice() as discount_price, 0 as used_price
    from albums b 
    where value(b) is of (mp3_type)

select albumTitle, mediaType, albumPrice, discount_price, used_price
from all_albums 
where used_price = (select max(used_price) from all_albums)

/*Q8*/
create or replace function containsText(pString1 in varchar2, pString2 in varchar2) return integer 
is
	is_contained integer := 0;
begin
	if instr(pString1, pString2) != 0 then
		is_contained := 1;
	end if;
	return is_contained;
end containsText;

select a.albumTitle, r.reviewText, r.reviewScore
from albums a, table(a.albumReviews) r
where containsText(r.reviewText, 'Great') = 1





