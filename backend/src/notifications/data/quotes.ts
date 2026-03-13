export interface MotivationalQuote {
  id: string;
  text: string;
  author: string;
  category: 'stoic' | 'proverb' | 'healing' | 'discipline' | 'encouragement';
}

export const BUILT_IN_QUOTES: MotivationalQuote[] = [
  // ─── Stoic Philosophy ───
  { id: 's1', text: 'Chướng ngại trên đường, chính là con đường.', author: 'Marcus Aurelius', category: 'stoic' },
  { id: 's2', text: 'Hạnh phúc phụ thuộc vào chất lượng suy nghĩ của bạn.', author: 'Marcus Aurelius', category: 'stoic' },
  { id: 's3', text: 'Bạn có sức mạnh vượt qua mọi thứ — hãy nhớ điều đó.', author: 'Marcus Aurelius', category: 'stoic' },
  { id: 's4', text: 'Đừng giải thích triết lý của bạn. Hãy thể hiện nó.', author: 'Epictetus', category: 'stoic' },
  { id: 's5', text: 'Khó khăn tôi luyện nên những người mạnh mẽ.', author: 'Seneca', category: 'stoic' },
  { id: 's6', text: 'Không phải vì khó mà ta không dám, mà vì ta không dám nên mới khó.', author: 'Seneca', category: 'stoic' },
  { id: 's7', text: 'Thời gian ta có thì ít, nhưng ta lãng phí rất nhiều.', author: 'Seneca', category: 'stoic' },
  { id: 's8', text: 'Hãy kiểm soát những gì bạn có thể. Bỏ qua phần còn lại.', author: 'Epictetus', category: 'stoic' },
  { id: 's9', text: 'Mỗi ngày mới là một cuộc đời mới cho người khôn ngoan.', author: 'Seneca', category: 'stoic' },
  { id: 's10', text: 'Bạn là tổng thể của những thói quen bạn lặp lại.', author: 'Marcus Aurelius', category: 'stoic' },

  // ─── Proverbs / Tục ngữ ───
  { id: 'p1', text: 'Có công mài sắt, có ngày nên kim.', author: 'Tục ngữ Việt Nam', category: 'proverb' },
  { id: 'p2', text: 'Kiến tha lâu cũng đầy tổ.', author: 'Tục ngữ Việt Nam', category: 'proverb' },
  { id: 'p3', text: 'Đi một ngày đàng, học một sàng khôn.', author: 'Tục ngữ Việt Nam', category: 'proverb' },
  { id: 'p4', text: 'Giọt nước lâu ngày cũng mòn đá.', author: 'Tục ngữ', category: 'proverb' },
  { id: 'p5', text: 'Hành trình ngàn dặm bắt đầu từ một bước chân.', author: 'Lão Tử', category: 'proverb' },
  { id: 'p6', text: 'Cây ngay không sợ chết đứng, người học không sợ thất bại.', author: 'Tục ngữ', category: 'proverb' },
  { id: 'p7', text: 'Học, học nữa, học mãi.', author: 'Lenin', category: 'proverb' },
  { id: 'p8', text: 'Không thầy đố mày làm nên — nhưng tự học là bước tiến xa nhất.', author: 'Tục ngữ (phỏng theo)', category: 'proverb' },
  { id: 'p9', text: 'Thất bại là mẹ thành công.', author: 'Tục ngữ', category: 'proverb' },
  { id: 'p10', text: 'Một chút mỗi ngày, tạo nên điều phi thường.', author: '', category: 'proverb' },

  // ─── Healing / Chữa lành ───
  { id: 'h1', text: 'Bạn không cần phải hoàn hảo, chỉ cần bắt đầu thôi.', author: '', category: 'healing' },
  { id: 'h2', text: 'Hôm nay khó khăn, nhưng bạn đã rất giỏi rồi.', author: '', category: 'healing' },
  { id: 'h3', text: 'Nghỉ ngơi cũng là một dạng tiến bộ. Đừng quá khắt khe với bản thân.', author: '', category: 'healing' },
  { id: 'h4', text: 'Bạn đã đi rất xa rồi. Hãy tự hào về bản thân nhé.', author: '', category: 'healing' },
  { id: 'h5', text: 'Không ai sinh ra đã giỏi. Mọi chuyên gia đều từng là người mới.', author: '', category: 'healing' },
  { id: 'h6', text: 'Hãy dịu dàng với bản thân. Bạn đang cố gắng, và điều đó rất đáng quý.', author: '', category: 'healing' },
  { id: 'h7', text: 'Sai lầm không định nghĩa bạn. Cách bạn đứng dậy mới là điều quan trọng.', author: '', category: 'healing' },
  { id: 'h8', text: 'Bạn xứng đáng được trở nên tốt hơn mỗi ngày.', author: '', category: 'healing' },
  { id: 'h9', text: 'Đôi khi tiến bộ là lặng lẽ, nhưng nó vẫn luôn ở đó.', author: '', category: 'healing' },
  { id: 'h10', text: 'Hãy tin rằng mọi nỗ lực nhỏ đều có ý nghĩa.', author: '', category: 'healing' },

  // ─── Discipline / Kỷ luật ───
  { id: 'd1', text: 'Kỷ luật là cầu nối giữa mục tiêu và thành tựu.', author: 'Jim Rohn', category: 'discipline' },
  { id: 'd2', text: 'Động lực giúp bạn bắt đầu. Thói quen giúp bạn đi tiếp.', author: 'Jim Ryun', category: 'discipline' },
  { id: 'd3', text: 'Thành công là tổng của những nỗ lực nhỏ, lặp đi lặp lại mỗi ngày.', author: 'Robert Collier', category: 'discipline' },
  { id: 'd4', text: 'Hôm nay bạn làm điều người khác không muốn, ngày mai bạn sẽ có điều người khác không thể.', author: 'Jerry Rice', category: 'discipline' },
  { id: 'd5', text: 'Không có đường tắt đến bất kỳ nơi nào đáng đến.', author: 'Beverly Sills', category: 'discipline' },
  { id: 'd6', text: 'Người kỷ luật không bao giờ hối hận.', author: '', category: 'discipline' },
  { id: 'd7', text: 'Mỗi ngày bạn không học, là một ngày bạn đang đứng yên.', author: '', category: 'discipline' },
  { id: 'd8', text: 'Bạn không cần thêm thời gian, bạn cần thêm kỷ luật.', author: '', category: 'discipline' },
  { id: 'd9', text: '5 phút hôm nay tốt hơn 0 phút. Hãy bắt đầu ngay.', author: '', category: 'discipline' },
  { id: 'd10', text: 'Thói quen nhỏ, kết quả lớn. Đừng đánh giá thấp sự nhất quán.', author: '', category: 'discipline' },

  // ─── Encouragement / Khuyến khích ───
  { id: 'e1', text: 'Streak của bạn là bằng chứng cho sự kiên trì. Giữ vững nhé!', author: '', category: 'encouragement' },
  { id: 'e2', text: 'Mỗi bài học bạn hoàn thành đều đưa bạn gần hơn mục tiêu.', author: '', category: 'encouragement' },
  { id: 'e3', text: 'Bạn đang xây dựng phiên bản tốt nhất của mình. Đừng dừng lại!', author: '', category: 'encouragement' },
  { id: 'e4', text: 'Học tập là khoản đầu tư không bao giờ lỗ.', author: 'Benjamin Franklin', category: 'encouragement' },
  { id: 'e5', text: 'Ngày hôm qua bạn đã rất tuyệt. Hôm nay hãy còn tuyệt hơn!', author: '', category: 'encouragement' },
  { id: 'e6', text: 'Chỉ cần 1 bài học hôm nay, bạn đã hơn hàng triệu người khác.', author: '', category: 'encouragement' },
  { id: 'e7', text: 'Bạn không học một mình. Cả cộng đồng đang cùng bạn.', author: '', category: 'encouragement' },
  { id: 'e8', text: 'Tri thức là sức mạnh. Bạn đang mạnh hơn mỗi ngày.', author: 'Francis Bacon', category: 'encouragement' },
  { id: 'e9', text: 'Cảm ơn bạn đã quay lại. Hành trình của bạn chưa kết thúc.', author: '', category: 'encouragement' },
  { id: 'e10', text: 'Bạn đã chọn học — và đó là quyết định đúng đắn nhất hôm nay.', author: '', category: 'encouragement' },
];
